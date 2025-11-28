// mobile_network_config.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mini_social_network/utils/auth_error_notifier.dart';

const storage = FlutterSecureStorage();

Dio getClient() {
  final dio = Dio();

  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  dio.options.sendTimeout = const Duration(seconds: 30);

  (dio.httpClientAdapter as dynamic).onHttpClientCreate = (HttpClient client) {
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return true;
    };
    return client;
  };

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      String? cookie = await storage.read(key: 'authCookie');
      if (options.path != '/login' && cookie != null) {
        options.headers['Cookie'] = cookie;
      }
      return handler.next(options);
    },
    onResponse: (response, handler) async {
      if (response.headers.map.containsKey(HttpHeaders.setCookieHeader)) {
        String rawCookie =
            response.headers[HttpHeaders.setCookieHeader]!.join('; ');
        await storage.write(key: 'authCookie', value: rawCookie);
      }
      return handler.next(response);
    },
    onError: (DioException error, handler) async {
      if (error.response?.statusCode == 401) {
        print('🔒 [Dio] Erreur 401 - Session expirée');

        // Nettoyer le storage
        await storage.delete(key: 'authCookie');
        await storage.delete(key: 'user');

        // Notifier via le stream global
        AuthErrorNotifier.notify();
      }

      return handler.next(error);
    },
  ));

  return dio;
}

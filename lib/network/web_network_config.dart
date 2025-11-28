// web_network_config.dart
import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mini_social_network/utils/auth_error_notifier.dart';

const storage = FlutterSecureStorage();

Dio getClient() {
  final dio = Dio()
    ..httpClientAdapter = BrowserHttpClientAdapter()
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? cookie = await storage.read(key: 'authCookie');
        if (options.path != '/login' && cookie != null) {
          options.headers['Authorization'] = 'Bearer $cookie';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        if (response.data is Map &&
            (response.data as Map).containsKey('Set-Cookie')) {
          final setCookieHeader = response.data['Set-Cookie'];
          final RegExp cookieRegExp = RegExp(r'connect\.sid=([^;]+)');
          final match = cookieRegExp.firstMatch(setCookieHeader);
          if (match != null) {
            final rawCookie = match.group(0);
            if (rawCookie != null) {
              await storage.write(key: 'authCookie', value: rawCookie);
            }
          }
        }
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          print('🔒 [Dio] Erreur 401 - Session expirée');

          await storage.delete(key: 'authCookie');
          await storage.delete(key: 'user');

          AuthErrorNotifier.notify();
        }

        return handler.next(error);
      },
    ));
  return dio;
}

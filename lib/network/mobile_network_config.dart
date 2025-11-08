import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

Dio getClient() {
  final dio = Dio();

  // Augmenter les délais d'attente
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  dio.options.sendTimeout = const Duration(seconds: 30);

  // Alternative pour ignorer les erreurs de certificat SSL
  (dio.httpClientAdapter as dynamic).onHttpClientCreate = (HttpClient client) {
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      return true; // Ignorer tous les certificats (uniquement pour le débogage)
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
        String rawCookie = response.headers[HttpHeaders.setCookieHeader]!.join('; ');
        await storage.write(key: 'authCookie', value: rawCookie);
      }
      return handler.next(response);
    },
  ));

  return dio;
}

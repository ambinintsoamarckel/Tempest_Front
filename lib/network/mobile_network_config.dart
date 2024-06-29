import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

Dio getClient() {
  return Dio()
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('object ${options.path} ${options.baseUrl} ');
        print('plateforme android');

        String? cookie = await storage.read(key: 'authCookie');

        if (options.path != '/login' && cookie != null) {
          options.headers['Cookie'] = cookie;
        }
        print('plateforme android236');
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        print('Response plateforme android ${response.headers}');
        if (response.headers.map.containsKey(HttpHeaders.setCookieHeader)) {
          String rawCookie = response.headers[HttpHeaders.setCookieHeader]!.join('; ');
          await storage.write(key: 'authCookie', value: rawCookie);
        }
        return handler.next(response);
      },
    ));
}

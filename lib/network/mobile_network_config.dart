import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

Dio getClient() {
  return Dio()
    ..interceptors.add(InterceptorsWrapper(
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
}

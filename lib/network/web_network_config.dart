import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

Dio getClient() {
 final dio = Dio()
    ..httpClientAdapter = BrowserHttpClientAdapter()
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('Request on Web Platform');
        String? cookie = await storage.read(key: 'authCookie');
      if (options.path != '/login' && cookie != null) {
          options.headers['Authorization'] = 'Bearer $cookie'; // Utiliser un en-tête personnalisé
        }
        return handler.next(options);
      },
     onResponse: (response, handler) async {
        print('Response on Web Platform');
        
        // Vérifiez la présence de 'Set-Cookie' dans les données de la réponse
        
        if (response.data is Map && (response.data as Map).containsKey('Set-Cookie')) {
          // Utilisez une expression régulière pour extraire `connect.sid`
          final setCookieHeader = response.data['Set-Cookie'];
          final RegExp cookieRegExp = RegExp(r'connect\.sid=([^;]+)');
          final match = cookieRegExp.firstMatch(setCookieHeader);
          if (match != null) {
            final rawCookie = match.group(0);
            if (rawCookie != null) {
              print('Extracted Cookie: $rawCookie');
              await storage.write(key: 'authCookie', value: rawCookie);
            }
          }
        }
        
        return handler.next(response);
      },
    ));
  return dio;
}

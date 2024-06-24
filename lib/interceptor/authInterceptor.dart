import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final storage = FlutterSecureStorage();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Ajout du cookie d'authentification aux en-têtes
    String? cookie = await storage.read(key: 'authCookie');
    if (cookie != null) {
      options.headers['Cookie'] = cookie;
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Récupérer et stocker le cookie de la réponse
    String? rawCookie = response.headers['set-cookie']?.first;
    print('Je passe dans l\'interception $rawCookie  ${response.headers}');
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      String cookie = (index == -1) ? rawCookie : rawCookie.substring(0, index);
      await storage.write(key: 'authCookie', value: cookie);
    }
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    return super.onError(err, handler);
  }
}

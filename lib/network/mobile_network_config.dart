// mobile_network_config.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mini_social_network/utils/auth_error_notifier.dart';

const storage = FlutterSecureStorage();

// ✅ Liste des routes qui ne nécessitent PAS de cookie
const List<String> publicRoutes = [
  '/login',
  '/session',
  '/signup',
];

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
      print('📤 [Dio Request] ${options.method} ${options.path}');

      // ✅ Vérifier si la route est publique
      bool isPublicRoute = publicRoutes.any((route) => options.path == route);

      if (!isPublicRoute) {
        String? cookie = await storage.read(key: 'authCookie');
        if (cookie != null) {
          options.headers['Cookie'] = cookie;
          print(
              '🍪 [Request] Cookie envoyé: ${cookie.length > 50 ? cookie.substring(0, 50) + "..." : cookie}');
        } else {
          print('⚠️ [Request] Pas de cookie disponible pour ${options.path}');
        }
      } else {
        print(
            '🔓 [Request] Route publique, pas de cookie nécessaire: ${options.path}');
      }

      return handler.next(options);
    },
    onResponse: (response, handler) async {
      print(
          '📥 [Dio Response] ${response.requestOptions.path} - Status: ${response.statusCode}');

      if (response.headers.map.containsKey(HttpHeaders.setCookieHeader)) {
        List<String> cookies = response.headers[HttpHeaders.setCookieHeader]!;
        print(
            '🍪 [Response] ${cookies.length} cookie(s) reçu(s) dans les headers');

        // Afficher tous les cookies reçus
        for (int i = 0; i < cookies.length; i++) {
          print(
              '   Cookie $i: ${cookies[i].length > 80 ? cookies[i].substring(0, 80) + "..." : cookies[i]}');
        }

        // ✅ Chercher le cookie SIGNÉ généré par Express/Passport
        String? signedCookie;
        for (var cookie in cookies) {
          print('   🔍 Analyse du cookie: ${cookie.substring(0, 50)}...');

          // Le cookie signé commence par connect.sid=s%3A
          if (cookie.contains('connect.sid=s%3A')) {
            final match = RegExp(r'connect\.sid=s%3A[^;]+').firstMatch(cookie);
            if (match != null) {
              signedCookie = match.group(0);
              print(
                  '   ✅ Cookie SIGNÉ trouvé: ${signedCookie!.substring(0, 50)}...');
              break;
            }
          } else {
            print('   ⚠️  Cookie NON signé (pas de s%3A)');
          }
        }

        // Sauvegarder le cookie signé (prioritaire) ou le premier cookie disponible
        if (signedCookie != null) {
          await storage.write(key: 'authCookie', value: signedCookie);
          print('💾 [Response] Cookie SIGNÉ sauvegardé dans storage');
          print('   Valeur: ${signedCookie.substring(0, 50)}...');
        } else if (cookies.isNotEmpty) {
          print(
              '⚠️  [Response] Aucun cookie signé trouvé, utilisation du fallback');

          // Fallback: extraire connect.sid du premier cookie
          final match = RegExp(r'connect\.sid=[^;]+').firstMatch(cookies.first);
          if (match != null) {
            final fallbackCookie = match.group(0)!;
            await storage.write(key: 'authCookie', value: fallbackCookie);
            print(
                '💾 [Response] Cookie FALLBACK sauvegardé: ${fallbackCookie.substring(0, 50)}...');
          } else {
            print('❌ [Response] Impossible d\'extraire connect.sid du cookie');
          }
        } else {
          print('❌ [Response] Aucun cookie reçu');
        }

        // Vérifier ce qui est dans le storage après sauvegarde
        String? storedCookie = await storage.read(key: 'authCookie');
        print(
            '📦 [Storage] Cookie actuellement stocké: ${storedCookie?.substring(0, 50)}...');
      } else {
        print('❌ [Response] Pas de Set-Cookie dans les headers');
      }

      return handler.next(response);
    },
    onError: (DioException error, handler) async {
      print(
          '❌ [Dio Error] ${error.requestOptions.path} - Status: ${error.response?.statusCode}');
      print('   Message: ${error.message}');

      if (error.response?.statusCode == 401) {
        // ✅ Ne pas nettoyer si c'est une route publique qui renvoie 401
        bool isPublicRoute =
            publicRoutes.any((route) => error.requestOptions.path == route);

        if (isPublicRoute) {
          print(
              '🔓 [Dio] 401 sur route publique ${error.requestOptions.path} - pas de nettoyage');
        } else {
          print('🔒 [Dio] Erreur 401 - Session expirée');

          // Afficher le cookie qui a causé le 401
          String? failedCookie = await storage.read(key: 'authCookie');
          print('   Cookie ayant échoué: ${failedCookie?.substring(0, 50)}...');

          // Nettoyer le storage
          await storage.delete(key: 'authCookie');
          await storage.delete(key: 'user');
          print('🧹 [Storage] authCookie et user supprimés');

          // Notifier via le stream global
          AuthErrorNotifier.notify();
        }
      }

      return handler.next(error);
    },
  ));

  return dio;
}

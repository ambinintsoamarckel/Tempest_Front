import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../network/network_config.dart';
import '../socket/socket_service.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../models/profile.dart' as profile;

class UserService {
  final storage = const FlutterSecureStorage();
  final Dio dio = NetworkConfig().client;
  final socketService = SocketService();

  Future<UserModel?> createUserWithEmailAndPassword(
      String email, String password, String nom) async {
    try {
      final response = await dio.post(
        '/utilisateurs',
        data: jsonEncode({
          'email': email,
          'password': password,
          'nom': nom,
        }),
      );

      if (response.statusCode == 201) {
        final user = await signInWithEmailAndPassword(email, password);
        return user;
      } else {
        throw Exception('Erreur lors de la création de l\'utilisateur');
      }
    } catch (e) {
      print('user Creation error: $e');
      rethrow;
    }
  }

  Future<bool> logout() async {
    try {
      final response = await dio.post('/logout');
      await storage.delete(key: 'authCookie');
      await storage.delete(key: 'user');
      return response.statusCode == 200;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  Future<bool> delete() async {
    try {
      final response = await dio.delete('/me');
      await storage.delete(key: 'authCookie');
      await storage.delete(key: 'user');
      return response.statusCode == 204;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    final response = await dio.post('/login',
        data: jsonEncode({
          'username': email,
          'password': password,
        }), options: Options(
      validateStatus: (status) {
        return status! <
            500; // Ne lance pas d'exception pour les codes de statut inférieurs à 500
      },
    ));
    print('eto lekaaaa :');
    print(response.data);
    if (response.statusCode == 200) {
      final data = response.data['user'];
      final user = UserModel.fromJson(data);
      await storage.write(key: 'user', value: jsonEncode(user.uid));
      socketService.initializeSocket(user.uid);
      return user;
    } else if (response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 404) {
      final errorMessage =
          response.data['message'] ?? 'Erreur lors de la connexion';
      throw Exception(errorMessage);
    } else {
      throw Exception('Problème de serveur');
    }
  }

  Future<UserModel> checkSession() async {
    try {
      final response = await dio.get('/session');
      if (response.statusCode == 200) {
        final data = response.data;
        final user = UserModel.fromJson(data);

        await storage.write(key: 'user', value: jsonEncode(user.uid));
        return user;
      } else {
        throw Exception('Erreur lors de la création de l\'utilisateur');
      }
    } catch (e) {
      print('Session check error: $e');
      rethrow;
    }
  }

  Future<profile.UserModel> getUserProfile() async {
    final response = await dio.get('/me');

    if (response.statusCode == 200) {
      final data = response.data;
      return profile.UserModel.fromJson(data);
    } else {
      throw Exception('Erreur lors de la récupération du profil utilisateur');
    }
  }

  Future<void> updateUser(UserModel user) async {
    final response = await dio.put(
      '/me',
      data: jsonEncode(user.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur');
    }
  }

// Flutter
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/me', data: data);

      // ✅ Laisser le temps au backend de sauvegarder
      await Future.delayed(const Duration(milliseconds: 150));

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur: $e');
      return false;
    }
  }

  Future<bool> updatePassword(String oldPassword, newPassword) async {
    try {
      final response = await dio.put(
        '/me/changePassword',
        data: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
        options: Options(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Dans UserService
  Future<User?> getCurrentUser() async {
    try {
      final userIdJson = await storage.read(key: 'user');
      if (userIdJson == null) {
        return null;
      }

      final userId = jsonDecode(userIdJson);

      // Récupère le profil complet de l'utilisateur
      final response = await dio.get('/me');

      if (response.statusCode == 200) {
        final data = response.data;
        return User.fromJson(data);
      } else {
        throw Exception(
            'Erreur lors de la récupération de l\'utilisateur actuel');
      }
    } catch (e) {
      print('getCurrentUser error: $e');
      return null;
    }
  }

  // Dans UserService
  Future<User?> getContactById(String contactId) async {
    try {
      final response = await dio.get('/utilisateurs/$contactId');

      if (response.statusCode == 200) {
        final data = response.data;
        return User.fromJson(data);
      } else {
        throw Exception('Erreur lors de la récupération du contact');
      }
    } catch (e) {
      print('getContactById error: $e');
      return null;
    }
  }

  Future<bool> updateProfilePhoto(String filePath) async {
    try {
      // Déterminer le type MIME
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      MultipartFile file = await MultipartFile.fromFile(
        filePath,
        contentType: MediaType.parse(mimeType),
      );

      FormData formData = FormData.fromMap({
        'photo': file,
      });

      final response = await dio.put(
        '/me/changePhoto',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../network/network_config.dart';
import '../socket/socket_service.dart';

class UserService {
  final storage = FlutterSecureStorage();
  final Dio dio = NetworkConfig().client;
  final socketService = SocketService();

  Future<UserModel?> createUserWithEmailAndPassword(String email, String password, String nom) async {
    final response = await dio.post(
      '/utilisateurs',
      data: jsonEncode({
        'email': email,
        'password': password,
        'nom': nom,
      }),
    );

    if (response.statusCode == 201) {
      final data = response.data['user'];
      final user = UserModel.fromJson(data);
      
      await storage.write(key: 'user', value: jsonEncode(user.uid));
      return user;
    } else {
      throw Exception('Erreur lors de la création de l\'utilisateur');
    }
  }

  Future<bool> logout() async {
    try {
      final response = await dio.post('/logout'); 
      await storage.delete(key: 'authCookie');
      await storage.delete(key: 'user');
      return response.statusCode==200;

    } catch (e) {
      print('Logout error: $e');
      return false;
    } 
  }

  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await dio.post(
        '/login',
        data: jsonEncode({
          'username': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data['user'];
        final user = UserModel.fromJson(data);
        await storage.write(key: 'user', value: jsonEncode(user.uid));
        socketService.initializeSocket(user.uid);
        return user;
      } else {
        throw Exception('Erreur lors de la connexion');
      }
    } catch (e) {
      throw Exception('Erreur lors de la connexion $e');
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

  Future<UserModel?> getUserProfile(String userId) async {
    final response = await dio.get('/me');

    if (response.statusCode == 200) {
      final data = response.data;
      return UserModel.fromJson(data);
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

  Future<bool> updateUserProfile(String name, String email) async {
    String? token = await storage.read(key: 'token');
    try {
      final response = await dio.put(
        '/me',
        data: jsonEncode({
          'name': name,
          'email': email,
        }),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> updatePassword(String oldPassword, newPassword) async {
    String? token = await storage.read(key: 'token');
    try {
      final response = await dio.put(
        '/me/changePassword',
        data: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> updateProfilePhoto(String filePath) async {
    String? token = await storage.read(key: 'token');
    try {
      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath),
      });

      final response = await dio.put(
        '/me/changePhoto',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
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

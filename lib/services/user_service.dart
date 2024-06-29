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

  Future<UserModel?> createUserWithEmailAndPassword(String email, String password, String name, String photoUrl) async {
    final response = await dio.post(
      '/utilisateurs',
      data: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'photoUrl': photoUrl,
      }),
    );

    if (response.statusCode == 201) {
      final data = response.data['user'];
      final user = UserModel.fromJson(data);
      
      await storage.write(key: 'user', value: jsonEncode(user.toJson()));
      return user;
    } else {
      throw Exception('Erreur lors de la création de l\'utilisateur');
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

  Future<UserModel?> getUserProfile(String userId) async {
    final response = await dio.get('/utilisateurs/$userId');

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
}

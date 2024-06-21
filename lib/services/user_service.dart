import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class UserService {
  final String baseUrl = 'http://mahm.tempest.dov:3000'; // Remplacez par l'URL de votre backend
  final storage = FlutterSecureStorage();

  Future<UserModel?> createUserWithEmailAndPassword(String email, String password, String name, String photoUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/utilisateurs'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
        'name': name,
        'photoUrl': photoUrl,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data);
      await storage.write(key: 'user', value: jsonEncode(user.toJson()));
      return user;
    } else {
      // Gestion des erreurs
      throw Exception('Erreur lors de la création de l\'utilisateur');
    }
  }

  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data);
        await storage.write(key: 'user', value: jsonEncode(user.toJson()));
        return user;
      } else {
        throw Exception('Erreur lors de la connexion');
      }
    } catch (e) {
      throw Exception('Erreur lors de la connexion');
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/utilisateurs/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      // Gestion des erreurs
      throw Exception('Erreur lors de la récupération du profil utilisateur');
    }
  }

  Future<void> updateUser(UserModel user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode != 200) {
      // Gestion des erreurs
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur');
    }
  }
}

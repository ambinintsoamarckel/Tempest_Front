import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login.dart';

class AuthService {
  final String baseUrl ;

  AuthService({required this.baseUrl});

  Future<User?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to login');
    }
  }
}

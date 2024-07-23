import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _photoController = TextEditingController();
  final UserService _userService = UserService();

  void _register() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String nom = _nameController.text.trim();
    String photo = _photoController.text.trim();
    UserModel? user = await _userService.createUserWithEmailAndPassword(email, password, nom);
    if (user != null) {
      // Navigate to the main screen or home screen
      Navigator.pushReplacementNamed(context, '/home', arguments: user);
    } else {
      // Show error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

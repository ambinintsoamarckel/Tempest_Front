import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _photoController = TextEditingController();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.user.email;
    _nomController.text = widget.user.nom;
    _photoController.text = widget.user.photo;
  }

  void _updateProfile() async {
    String email = _emailController.text.trim();
    String nom = _nomController.text.trim();
    String photo = _photoController.text.trim();

    UserModel updatedUser = widget.user.copyWith(
      email: email,
      nom: nom,
      photo: photo,
    );

    await _userService.updateUser(updatedUser);

    Navigator.pop(context, updatedUser);
  }

  void _logout(BuildContext context) async {
    bool deconected=await _userService.logout();
    if (deconected) {
          Navigator.pushReplacementNamed(context, '/login');
      
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'nom'),
            ),
            TextField(
              controller: _photoController,
              decoration: const InputDecoration(labelText: 'Photo URL'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Update Profile'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _logout(context);
              },
              child: Text('Déconnexion'),
            ),
          ],
        ),
      ),
    );
  }
}

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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.user.email;
    _nameController.text = widget.user.name;
    _photoUrlController.text = widget.user.photoUrl;
  }

  void _updateProfile() async {
    String email = _emailController.text.trim();
    String name = _nameController.text.trim();
    String photoUrl = _photoUrlController.text.trim();

    UserModel updatedUser = widget.user.copyWith(
      email: email,
      name: name,
      photoUrl: photoUrl,
    );

    await _userService.updateUser(updatedUser);

    Navigator.pop(context, updatedUser);
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
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _photoUrlController,
              decoration: const InputDecoration(labelText: 'Photo URL'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

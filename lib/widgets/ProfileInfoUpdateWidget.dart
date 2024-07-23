import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class ProfileInfoUpdateWidget extends StatefulWidget {
  final UserModel user;

  const ProfileInfoUpdateWidget({super.key, required this.user});

  @override
  _ProfileInfoUpdateWidgetState createState() => _ProfileInfoUpdateWidgetState();
}

class _ProfileInfoUpdateWidgetState extends State<ProfileInfoUpdateWidget> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.user.email;
    _nomController.text = widget.user.nom;
  }

  void _updateProfile() async {
    String email = _emailController.text.trim();
    String nom = _nomController.text.trim();

    try {
      UserModel updatedUser = widget.user.copyWith(email: email, nom: nom);
      await _userService.updateUser(updatedUser);
      Navigator.pop(context, updatedUser);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour du profil')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _nomController,
            decoration: const InputDecoration(labelText: 'Nom'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _updateProfile,
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/user_service.dart';

class PasswordChangeWidget extends StatefulWidget {


  const PasswordChangeWidget({super.key});

  @override
  _PasswordChangeWidgetState createState() => _PasswordChangeWidgetState();
}

class _PasswordChangeWidgetState extends State<PasswordChangeWidget> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final UserService _userService = UserService();

  void _changePassword() async {
    String oldPassword = _oldPasswordController.text.trim();
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les nouveaux mots de passe ne correspondent pas')),
      );
      return;
    }

    try {
      bool success = await _userService.updatePassword(oldPassword, newPassword);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du changement de mot de passe')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du changement de mot de passe')),
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
            controller: _oldPasswordController,
            decoration: const InputDecoration(labelText: 'Ancien mot de passe'),
            obscureText: true,
          ),
          TextField(
            controller: _newPasswordController,
            decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
            obscureText: true,
          ),
          TextField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(labelText: 'Confirmer le nouveau mot de passe'),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _changePassword,
            child: const Text('Changer le mot de passe'),
          ),
        ],
      ),
    );
  }
}

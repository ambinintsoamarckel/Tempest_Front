import 'package:flutter/material.dart';
import '../services/user_service.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({super.key});

  final UserService _userService = UserService();

  void _logout(BuildContext context) async {
    bool deconected=await _userService.logout();
    if (deconected) {
          Navigator.pushReplacementNamed(context, '/login');
      
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon compte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Action à exécuter lors du clic sur l'icône des paramètres
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nom Utilisateur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Adresse email@example.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Action à exécuter lors du clic sur le bouton
              },
              child: const Text('Modifier le profil'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _logout(context);
              },
              child: const Text('Déconnexion'),
            ),
          ],
        ),
      ),
    );
  }
}

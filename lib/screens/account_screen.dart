import 'package:flutter/material.dart';
import '../services/user_service.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({Key? key}) : super(key: key);

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
        title: Text('Mon compte'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
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
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            SizedBox(height: 20),
            Text(
              'Nom Utilisateur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Adresse email@example.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Action à exécuter lors du clic sur le bouton
              },
              child: Text('Modifier le profil'),
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

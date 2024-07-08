import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class ProfileInfoUpdateWidget extends StatefulWidget {
  final UserModel user;

  ProfileInfoUpdateWidget({required this.user});

  @override
  _ProfileInfoUpdateWidgetState createState() => _ProfileInfoUpdateWidgetState();
}

class _ProfileInfoUpdateWidgetState extends State<ProfileInfoUpdateWidget> {
  final _formKey = GlobalKey<FormState>();
  late String _username;
  late String _email;
  late String _password;

  @override
  void initState() {
    super.initState();
    _username = widget.user.nom;
    _email = widget.user.email;
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await Provider.of<UserService>(context, listen: false).updateUserProfile(
          _username,
          _email,
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil mis à jour avec succès')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la mise à jour du profil')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: _username,
            decoration: InputDecoration(labelText: 'Nom d\'utilisateur'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom d\'utilisateur';
              }
              return null;
            },
            onSaved: (value) {
              _username = value!;
            },
          ),
          TextFormField(
            initialValue: _email,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un email';
              }
              return null;
            },
            onSaved: (value) {
              _email = value!;
            },
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Mot de passe actuel'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre mot de passe actuel';
              }
              return null;
            },
            onSaved: (value) {
              _password = value!;
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _updateProfile,
            child: Text('Mettre à jour le profil'),
          ),
        ],
      ),
    );
  }
}

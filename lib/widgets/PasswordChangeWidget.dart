import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_service.dart';

class PasswordChangeWidget extends StatefulWidget {
  @override
  _PasswordChangeWidgetState createState() => _PasswordChangeWidgetState();
}

class _PasswordChangeWidgetState extends State<PasswordChangeWidget> {
  final _formKey = GlobalKey<FormState>();
  late String _oldPassword;
  late String _newPassword;
  late String _confirmNewPassword;

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_newPassword != _confirmNewPassword) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Les nouveaux mots de passe ne correspondent pas')));
        return;
      }

      try {
        await Provider.of<UserService>(context, listen: false).updatePassword(
          _oldPassword,
          _newPassword,
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mot de passe changé avec succès')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors du changement de mot de passe')));
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
            decoration: InputDecoration(labelText: 'Mot de passe actuel'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre mot de passe actuel';
              }
              return null;
            },
            onSaved: (value) {
              _oldPassword = value!;
            },
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Nouveau mot de passe'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nouveau mot de passe';
              }
              return null;
            },
            onSaved: (value) {
              _newPassword = value!;
            },
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Confirmer le nouveau mot de passe'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez confirmer votre nouveau mot de passe';
              }
              return null;
            },
            onSaved: (value) {
              _confirmNewPassword = value!;
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _changePassword,
            child: Text('Changer le mot de passe'),
          ),
        ],
      ),
    );
  }
}

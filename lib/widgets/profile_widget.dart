import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreenWidget extends StatefulWidget {
  final UserModel user;

  const ProfileScreenWidget({super.key, required this.user});

  @override
  _ProfileScreenWidgetState createState() => _ProfileScreenWidgetState();
}

class _ProfileScreenWidgetState extends State<ProfileScreenWidget> {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.user.presence == "en ligne" ? Color.fromARGB(255, 8, 199, 100) : Colors.transparent,
                  width: 3.0,
                ),
              ),
              child: CircleAvatar(
          backgroundImage: widget.user.photo != null
              ? NetworkImage(widget.user.photo!)
              : null,
          child: widget.user.photo == null ? const Icon(Icons.person) : null,
        ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.user.nom,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.user.email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/edit_profile', arguments: widget.user);
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
    );
  }
}

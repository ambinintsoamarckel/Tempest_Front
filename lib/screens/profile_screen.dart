import 'package:flutter/material.dart';
import 'package:mini_social_network/screens/contacts_screen.dart';
import 'package:mini_social_network/screens/home_screen.dart';
import 'package:mini_social_network/screens/messages_screen.dart';
import 'package:mini_social_network/screens/stories_screen.dart';
import '../services/user_service.dart';
import '../widgets/PasswordChangeWidget.dart';
import '../widgets/ProfileInfoUpdateWidget.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import 'dart:io';
import '../socket/socket_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late UserModel _user;
  final SocketService socketService=SocketService();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  void _showProfileInfoUpdateWidget() async {
    UserModel? updatedUser = await showModalBottomSheet<UserModel>(
      context: context,
      builder: (context) => ProfileInfoUpdateWidget(user: _user),
    );

    if (updatedUser != null) {
      setState(() {
        _user = updatedUser;
      });
    }
  }

  void _showPasswordChangeWidget() {
    showModalBottomSheet(
      context: context,
      builder: (context) => PasswordChangeWidget(user: _user),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      bool? confirm = await _showConfirmationDialog();
      if (confirm == true) {
        bool success = await _userService.updateProfilePhoto(pickedImage.path);
        if (success) {
          setState(() {
            widget.user.photo = pickedImage.path;
          });
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer'),
          content: Text('Voulez-vous vraiment changer votre photo de profil ?'),
          actions: <Widget>[
            TextButton(
              child: Text('Non'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Oui'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    bool deconnected = await _userService.logout();
    if (deconnected) {
      HomeScreenState.contactScreenState=GlobalKey<ContactScreenState>();
      HomeScreenState.conversationListScreen=GlobalKey<ConversationListScreenState>();
      HomeScreenState.storyScreenKey=GlobalKey<StoryScreenState>();
      
      Navigator.pushReplacementNamed(context, '/');
      socketService.disconnect();
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
            CircleAvatar(
              radius: 50,
              backgroundImage: widget.user.photo != null
              ? NetworkImage(widget.user.photo!)
              : null,
              child: IconButton(
                icon: Icon(Icons.camera_alt),
                onPressed: _pickImage,
              ),
            ),
            SizedBox(height: 16),
            Text(
              _user.nom,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _user.email,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showProfileInfoUpdateWidget,
              child: Text('Modifier les informations du profil'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showPasswordChangeWidget,
              child: Text('Modifier le mot de passe'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _logout(context),
              child: Text('Déconnexion'),
            ),
          ],
        ),
      ),
    );
  }
}

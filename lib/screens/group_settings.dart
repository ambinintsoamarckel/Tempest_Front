import 'dart:io';
import 'package:flutter/material.dart';
import '../models/group_message.dart';
import '../services/discu_group_service.dart';

class GroupSettingsScreen extends StatefulWidget {
  final Group groupe;

  GroupSettingsScreen({required this.groupe});

  @override
  _GroupSettingsScreenState createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late TextEditingController _groupNameController;
  late TextEditingController _groupPhotoController;
  TextEditingController _addMemberController = TextEditingController();
  final GroupChatService _groupService = GroupChatService(); // Instance du service de groupe

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController(text: widget.groupe.nom);
    _groupPhotoController = TextEditingController(text: widget.groupe.photo ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres du groupe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Modifier le nom du groupe :'),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: _updateGroupName,
              ),
            ),
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: 'Nom du groupe',
              ),
            ),
            SizedBox(height: 20.0),
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('Modifier la photo du groupe :'),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: _updateGroupPhoto,
              ),
            ),
            TextField(
              controller: _groupPhotoController,
              decoration: InputDecoration(
                hintText: 'URL de la nouvelle photo',
              ),
            ),
            SizedBox(height: 20.0),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text('Ajouter un membre :'),
              trailing: IconButton(
                icon: Icon(Icons.add),
                onPressed: _addMemberToGroup,
              ),
            ),
            TextField(
              controller: _addMemberController,
              decoration: InputDecoration(
                hintText: 'Nom d\'utilisateur du nouveau membre',
              ),
            ),
            SizedBox(height: 20.0),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Quitter le groupe :'),
              trailing: IconButton(
                icon: Icon(Icons.exit_to_app),
                onPressed: _leaveGroup,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateGroupName() async {
    String newGroupName = _groupNameController.text.trim();
    if (newGroupName.isNotEmpty) {
      try {
        // Assuming there's a method to update group name in GroupChatService
        await _groupService.updateGroupMessage(widget.groupe.id, "groupName", {"name": newGroupName});
        Navigator.pop(context); // Ferme l'écran des paramètres après la modification
      } catch (e) {
        // Gérer l'erreur ici
        print('Erreur lors de la mise à jour du nom du groupe : $e');
      }
    }
  }

  void _updateGroupPhoto() async {
    String newGroupPhotoUrl = _groupPhotoController.text.trim();
    if (newGroupPhotoUrl.isNotEmpty) {
      try {
        await _groupService.changeGroupPhoto(widget.groupe.id, File(newGroupPhotoUrl));
        Navigator.pop(context); // Ferme l'écran des paramètres après la modification
      } catch (e) {
        // Gérer l'erreur ici
        print('Erreur lors de la mise à jour de la photo du groupe : $e');
      }
    }
  }

  void _addMemberToGroup() async {
    String newMemberUsername = _addMemberController.text.trim();
    if (newMemberUsername.isNotEmpty) {
      try {
        await _groupService.addMemberToGroup(widget.groupe.id, newMemberUsername, {});
        Navigator.pop(context); // Ferme l'écran des paramètres après l'ajout
      } catch (e) {
        // Gérer l'erreur ici
        print('Erreur lors de l\'ajout d\'un membre au groupe : $e');
      }
    }
  }

  void _leaveGroup() async {
    try {
      await _groupService.removeMemberFromGroup(widget.groupe.id, "currentUserId"); // Remplacez "currentUserId" par l'ID de l'utilisateur actuel
      Navigator.pop(context); // Ferme l'écran des paramètres après avoir quitté le groupe
    } catch (e) {
      // Gérer l'erreur ici
      print('Erreur lors de la sortie du groupe : $e');
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupPhotoController.dispose();
    _addMemberController.dispose();
    super.dispose();
  }
}

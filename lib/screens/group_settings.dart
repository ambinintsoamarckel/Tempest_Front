import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_social_network/screens/membre_screen.dart';
import '../models/group_message.dart';
import '../services/discu_group_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mini_social_network/models/user.dart';

class GroupSettingsScreen extends StatefulWidget {
  Group groupe;

  GroupSettingsScreen({super.key, required this.groupe});

  @override
  _GroupSettingsScreenState createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late TextEditingController _groupNameController;
  late TextEditingController _groupDescriptionController;
  final TextEditingController _addMemberController = TextEditingController();
  final GroupChatService _groupService = GroupChatService();
  final ImagePicker _picker = ImagePicker();
  File? _groupPhotoFile;
  bool _isEditingName = false;
  bool _isEditingDescription = false;
  bool _isLoading = false;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController(text: widget.groupe.nom);
    _groupDescriptionController = TextEditingController(text: widget.groupe.description ?? '');
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    String? user = await storage.read(key: 'user');
    user = user!.replaceAll('"', '').trim();
    setState(() {
      _currentUserId = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isCreator = _currentUserId == widget.groupe.createur.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres du groupe'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                      backgroundImage: widget.groupe.photo != null ? NetworkImage(widget.groupe.photo!) : null,
                          child: widget.groupe.photo == null ? const Icon(Icons.groups, size: 50) : null,
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _showImagePickerOptions,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                const ListTile(
                  leading: Icon(Icons.group),
                  title: Text('Informations du groupe'),
                ),
                _buildTextField(
                  controller: _groupNameController,
                  labelText: 'Nom du groupe',
                  icon: Icons.edit,
                  isEditing: _isEditingName,
                  onPressedEdit: () {
                    setState(() {
                      _isEditingName = true;
                    });
                  },
                  onPressedSave: _updateGroupName,
                ),
                const SizedBox(height: 10.0),
                _buildTextField(
                  controller: _groupDescriptionController,
                  labelText: 'Description du groupe',
                  icon: Icons.edit,
                  isEditing: _isEditingDescription,
                  onPressedEdit: () {
                    setState(() {
                      _isEditingDescription = true;
                    });
                  },
                  onPressedSave: _updateGroupDescription,
                ),
                const SizedBox(height: 20.0),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('Créateur du groupe : ${widget.groupe.createur.nom}'),
                ),
                const SizedBox(height: 20.0),
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Ajouter un membre'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _ajouterMembre,
                  ),
                ),
                const SizedBox(height: 20.0),
                const ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Membres du groupe'),
                ),
                _buildMembersList(isCreator),
                const SizedBox(height: 20.0),
                ListTile(
                  leading: isCreator ? const Icon(Icons.delete) : const Icon(Icons.exit_to_app),
                  title: Text(isCreator ? 'Supprimer le groupe' : 'Quitter le groupe'),
                  trailing: IconButton(
                    icon: isCreator ? const Icon(Icons.delete, color: Colors.red) : const Icon(Icons.exit_to_app),
                    onPressed: isCreator ? _confirmDeleteGroup : _confirmLeaveGroup,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required bool isEditing,
    required VoidCallback onPressedEdit,
    required VoidCallback onPressedSave,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: isEditing,
            decoration: InputDecoration(
              labelText: labelText,
            ),
          ),
        ),
        IconButton(
          icon: Icon(isEditing ? Icons.check : icon),
          onPressed: isEditing ? onPressedSave : onPressedEdit,
        ),
      ],
    );
  }
  Widget _buildMembersList(bool isCreator) {
    if (_currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final members = widget.groupe.membres.where((member) => member.id != _currentUserId).toList();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: member.photo != null ? NetworkImage(member.photo!) : null,
            child: member.photo == null ? const Icon(Icons.person) : null,
          ),
          title: Text(member.nom),
          subtitle: Text(member.email),
          trailing: isCreator
              ? IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _removeMemberFromGroup(member.id),
                )
              : null,
        );
      },
    );
  }


  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Caméra'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _groupPhotoFile = File(pickedFile.path);
      });

      // Mettre à jour la photo du groupe sur le serveur
      _updateGroupPhoto();
    }
  }

  void _updateGroupName() async {
    setState(() {
      _isLoading = true;
    });
    String newGroupName = _groupNameController.text.trim();
    if (newGroupName.isNotEmpty) {
      try {
        final Group groupe = await _groupService.updateGroup(widget.groupe.id, {"nom": newGroupName});
        setState(() {
          widget.groupe = groupe;
          _isEditingName = false;
        });
      } catch (e) {
        print('Erreur lors de la mise à jour du nom du groupe : $e');
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _updateGroupDescription() async {
    setState(() {
      _isLoading = true;
    });
    String newGroupDescription = _groupDescriptionController.text.trim();
    if (newGroupDescription.isNotEmpty) {
      try {
        final Group groupe = await _groupService.updateGroup(widget.groupe.id, {"description": newGroupDescription});
        setState(() {
          widget.groupe = groupe;
          _isEditingDescription = false;
        });
      } catch (e) {
        print('Erreur lors de la mise à jour de la description du groupe : $e');
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _updateGroupPhoto() async {
    setState(() {
      _isLoading = true;
    });
    if (_groupPhotoFile != null) {
      try {
        final Group groupe = await _groupService.changeGroupPhoto(widget.groupe.id, _groupPhotoFile!.path);
        setState(() {
          widget.groupe = groupe;
          _groupPhotoFile = null;
        });
      } catch (e) {
        print('Erreur lors de la mise à jour de la photo du groupe : $e');
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _addMemberToGroup() async {
    String newMemberUsername = _addMemberController.text.trim();
    if (newMemberUsername.isNotEmpty) {
      try {
        await _groupService.addMemberToGroup(widget.groupe.id, newMemberUsername);
        setState(() {
          widget.groupe.membres.add(User(id: 'newId', nom: newMemberUsername, email: 'newEmail'));
        });
      } catch (e) {
        print('Erreur lors de l\'ajout d\'un membre au groupe : $e');
      }
    }
  }

  void _ajouterMembre() async {
    final addedContacts = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContaScreen(groupId: widget.groupe.id,)),
    );
    if (addedContacts != null) {
      setState(() {
        widget.groupe = addedContacts;
      });
    }
  }

  void _removeMemberFromGroup(String memberId) async {
    try {
      await _groupService.removeMemberFromGroup(widget.groupe.id, memberId);
      setState(() {
        widget.groupe.membres.removeWhere((member) => member.id == memberId);
      });
    } catch (e) {
      print('Erreur lors de la suppression d\'un membre du groupe : $e');
    }
  }

  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le groupe'),
        content: const Text('Êtes-vous sûr de vouloir quitter le groupe ?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Oui'),
            onPressed: () {
              Navigator.of(context).pop();
              _leaveGroup();
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le groupe'),
        content: const Text('Êtes-vous sûr de vouloir supprimer le groupe ? Cette action est irréversible.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Oui'),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteGroup();
            },
          ),
        ],
      ),
    );
  }

  void _leaveGroup() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_currentUserId != null) {
        await _groupService.quitGroup(widget.groupe.id);
     Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      print('Erreur lors de la sortie du groupe : $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _deleteGroup() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _groupService.deleteGroup(widget.groupe.id);
     Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      print('Erreur lors de la suppression du groupe : $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _addMemberController.dispose();
    super.dispose();
  }
}

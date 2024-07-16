import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mini_social_network/screens/contacts_screen.dart';
import 'package:mini_social_network/screens/home_screen.dart';
import 'package:mini_social_network/screens/messages_screen.dart';
import 'package:mini_social_network/screens/stories_screen.dart';
import '../services/user_service.dart';
import '../widgets/PasswordChangeWidget.dart';
import '../widgets/ProfileInfoUpdateWidget.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile.dart';
import '../socket/socket_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late UserModel _user;
  final SocketService socketService = SocketService();
  final ImagePicker _picker = ImagePicker();
  bool _isEditingName = false;
  bool _isEditingEmail = false;
  bool _isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
    });
    _user = await _userService.getUserProfile();
    setState(() {
      _nameController = TextEditingController(text: _user.nom);
      _emailController = TextEditingController(text: _user.email);
      _isLoading = false;
    });
  }

  Future<void> _reloadUser() async {
    await _loadUser();
  }

/*   void _showProfileInfoUpdateWidget() async {
    UserModel? updatedUser = await showModalBottomSheet<UserModel>(
      context: context,
      builder: (context) => ProfileInfoUpdateWidget(user: _user),
    );

    if (updatedUser != null) {
      await _reloadUser();
    }
  } */

  void _showPasswordChangeWidget() {
    showModalBottomSheet(
      context: context,
      builder: (context) => PasswordChangeWidget(),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Galerie'),
            onTap: () async {
              final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
              Navigator.of(context).pop();
              if (pickedImage != null) {
                bool? confirm = await _showConfirmationDialog();
                if (confirm == true) {
                  bool success = await _userService.updateProfilePhoto(pickedImage.path);
                  if (success) {
                    await _reloadUser();
                  }
                }
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_camera),
            title: Text('Caméra'),
            onTap: () async {
              final XFile? pickedImage = await _picker.pickImage(source: ImageSource.camera);
              Navigator.of(context).pop();
              if (pickedImage != null) {
                bool? confirm = await _showConfirmationDialog();
                if (confirm == true) {
                  bool success = await _userService.updateProfilePhoto(pickedImage.path);
                  if (success) {
                    await _reloadUser();
                  }
                }
              }
            },
          ),
        ],
      ),
    );
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
      HomeScreenState.contactScreenState = GlobalKey<ContactScreenState>();
      HomeScreenState.conversationListScreen = GlobalKey<ConversationListScreenState>();
      HomeScreenState.storyScreenKey = GlobalKey<StoryScreenState>();

      Navigator.pushReplacementNamed(context, '/');
      socketService.disconnect();
    }
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

  Widget _buildGroupList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Groupes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _user.groupes.length,
          itemBuilder: (context, index) {
            final group = _user.groupes[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: group.photo != null ? NetworkImage(group.photo!) : null,
                child: group.photo == null ? Icon(Icons.group) : null,
              ),
              title: Text(group.nom),
              subtitle: Text(group.description ?? ''),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _user.stories.length,
          itemBuilder: (context, index) {
            final story = _user.stories[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: story.type == 'image' ? NetworkImage(story.content) : null,
                child: story.type == 'text' ? Icon(Icons.text_fields) : null,
              ),
              title: Text(story.type),
              subtitle: Text(story.content),
            );
          },
        ),
      ],
    );
  }

  Widget _buildArchiveList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Archives',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _user.archives.length,
          itemBuilder: (context, index) {
            final archive = _user.archives[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: archive.type == 'image' ? NetworkImage(archive.content) : null,
                child: archive.type == 'text' ? Icon(Icons.text_fields) : null,
              ),
              title: Text(archive.type),
              subtitle: Text(archive.content),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Stack(
        children: [
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            )
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _user.photo != null ? NetworkImage(_user.photo!) : null,
                          child: _user.photo == null ? Icon(Icons.person, size: 50) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: Icon(Icons.camera_alt, color: Colors.black),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    labelText: 'Nom',
                    icon: Icons.edit,
                    isEditing: _isEditingName,
                    onPressedEdit: () {
                      setState(() {
                        _isEditingName = true;
                      });
                    },
                    onPressedSave: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      String newName = _nameController.text.trim();
                      if (newName.isNotEmpty) {
                        bool success = await _userService.updateUserProfile({"nom": newName});
                        if (success) {
                          setState(() {
                            _nameController.text = newName;
                            _isEditingName = false;
                          });
                        }
                      }
                      await _reloadUser();
                      setState(() {
                        _isLoading = false;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  _buildTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    icon: Icons.edit,
                    isEditing: _isEditingEmail,
                    onPressedEdit: () {
                      setState(() {
                        _isEditingEmail = true;
                      });
                    },
                    onPressedSave: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      String newEmail = _emailController.text.trim();
                      if (newEmail.isNotEmpty) {
                        bool success = await _userService.updateUserProfile({"email": newEmail});
                        if (success) {
                          setState(() {
                            _emailController.text = newEmail;
                            _isEditingEmail = false;
                          });
                        }
                      }
                      await _reloadUser();
                      setState(() {
                        _isLoading = false;
                      });
                    },
                  ),

                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showPasswordChangeWidget,
                    icon: Icon(Icons.lock),
                    label: Text('Modifier le mot de passe'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: Icon(Icons.exit_to_app),
                    label: Text('Déconnexion'),
                  ),
                  SizedBox(height: 20),
                  _buildGroupList(),
                  SizedBox(height: 20),
                  _buildStoryList(),
                  SizedBox(height: 20),
                  _buildArchiveList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

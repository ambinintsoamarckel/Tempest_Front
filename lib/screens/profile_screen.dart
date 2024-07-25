import 'package:flutter/material.dart';
import 'package:mini_social_network/screens/contacts_screen.dart';
import 'package:mini_social_network/screens/home_screen.dart';
import 'package:mini_social_network/screens/messages_screen.dart';
import 'package:mini_social_network/screens/stories_screen.dart';
import '../services/user_service.dart';
import 'archive_screen.dart' as archive;
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
  bool _showPasswordFields = false;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galerie'),
            onTap: () async {
              final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
              Navigator.of(context).pop();
              if (pickedImage != null) {
                bool? confirm = await _showConfirmationDialog('Voulez-vous vraiment changer votre photo de profil ?');
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
            leading: const Icon(Icons.photo_camera),
            title: const Text('Caméra'),
            onTap: () async {
              final XFile? pickedImage = await _picker.pickImage(source: ImageSource.camera);
              Navigator.of(context).pop();
              if (pickedImage != null) {
                bool? confirm = await _showConfirmationDialog('Voulez-vous vraiment changer votre photo de profil ?');
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

  Future<bool?> _showConfirmationDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Non'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Oui'),
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
    bool? confirm = await _showConfirmationDialog('Voulez-vous vraiment vous déconnecter ?');
    if (confirm == true) {
      bool deconnected = await _userService.logout();
      if (deconnected) {
        HomeScreenState.contactScreenState = GlobalKey<ContactScreenState>();
        HomeScreenState.conversationListScreen = GlobalKey<ConversationListScreenState>();
        HomeScreenState.storyScreenKey = GlobalKey<StoryScreenState>();

        Navigator.pushReplacementNamed(context, '/');
        socketService.disconnect();
      }
    }
  }

  void _deleteAccount(BuildContext context) async {
    bool? confirm = await _showConfirmationDialog('Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible.');
    if (confirm == true) {
      bool success = await _userService.delete();
      if (success) {
        HomeScreenState.contactScreenState = GlobalKey<ContactScreenState>();
        HomeScreenState.conversationListScreen = GlobalKey<ConversationListScreenState>();
        HomeScreenState.storyScreenKey = GlobalKey<StoryScreenState>();

        Navigator.pushReplacementNamed(context, '/');
        socketService.disconnect();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression du compte')),
        );
      }
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
        const Text(
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
                child: group.photo == null ? const Icon(Icons.group) : null,
              ),
              title: Text(group.nom),
              subtitle: Text(group.description ?? ''),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
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
    );
  }

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

  void _navigateToListScreen(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => archive.StoryScreen(stories:  _user.archives),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
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
                          backgroundImage: _user.photo != null ? NetworkImage(_user.photo) : null,
                          child: _user.photo == null ? const Icon(Icons.person, size: 50) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.black),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 20.0),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Modifier le mot de passe'),
                    trailing: IconButton(
                      icon: Icon(_showPasswordFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                      onPressed: () {
                        setState(() {
                          _showPasswordFields = !_showPasswordFields;
                        });
                      },
                    ),
                  ),
                  if (_showPasswordFields) _buildPasswordFields(),
                  const SizedBox(height: 20.0),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Déconnexion'),
                    trailing: IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      onPressed: () => _logout(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.delete_forever),
                    title: const Text('Supprimer mon compte'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _deleteAccount(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.archive),
                    title: const Text('Archives et Stories'),
                    onTap: () => _navigateToListScreen( 'Archives et Stories'),
                  ),
                  const SizedBox(height: 20),
                  _buildGroupList(),
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
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}


import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_social_network/services/user_service.dart';
import 'package:mini_social_network/models/profile.dart';
import 'package:mini_social_network/socket/socket_service.dart';
import 'package:mini_social_network/screens/contacts_screen.dart';
import 'package:mini_social_network/screens/home_screen.dart';
import 'package:mini_social_network/screens/messages_screen.dart';
import 'package:mini_social_network/screens/stories_screen.dart';
import 'package:mini_social_network/utils/screen_manager.dart';

class ProfileLogic extends ChangeNotifier {
  final UserService _userService = UserService();
  final SocketService _socketService = SocketService();
  final ImagePicker _picker = ImagePicker();
  final ScreenManager _screenManager = ScreenManager();

  UserModel? _user;
  bool _isLoading = false;
  bool _isEditingName = false;
  bool _isEditingEmail = false;
  bool _showPasswordFields = false;

  late TextEditingController nameController;
  late TextEditingController emailController;
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isEditingName => _isEditingName;
  bool get isEditingEmail => _isEditingEmail;
  bool get showPasswordFields => _showPasswordFields;

  ProfileLogic() {
    nameController = TextEditingController();
    emailController = TextEditingController();
  }

  // Chargement du profil utilisateur
  Future<void> loadUser() async {
    try {
      _setLoading(true);
      _user = await _userService.getUserProfile();

      if (_user != null) {
        nameController.text = _user!.nom;
        emailController.text = _user!.email;
      }
    } catch (e) {
      print('Erreur lors du chargement du profil: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Mise à jour de la photo de profil
  Future<bool> updateProfilePhoto(ImageSource source) async {
    try {
      final XFile? pickedImage = await _picker.pickImage(source: source);

      if (pickedImage != null) {
        _setLoading(true);
        bool success = await _userService.updateProfilePhoto(pickedImage.path);

        if (success) {
          await loadUser();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Erreur lors de la mise à jour de la photo: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mise à jour du nom
  Future<bool> updateName(String newName) async {
    if (newName.isEmpty || newName == _user?.nom) {
      _isEditingName = false;
      notifyListeners();
      return false;
    }

    try {
      _setLoading(true);
      bool success = await _userService.updateUserProfile({"nom": newName});

      if (success) {
        // Mettre à jour localement d'abord
        if (_user != null) {
          _user = UserModel(
            uid: _user!.uid,
            nom: newName,
            presence: _user!.presence,
            email: _user!.email,
            photo: _user!.photo,
            groupes: _user!.groupes,
            stories: _user!.stories,
            archives: _user!.archives,
          );
        }
        _isEditingName = false;

        // Recharger en arrière-plan sans bloquer l'UI
        loadUser();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la mise à jour du nom: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mise à jour de l'email
  Future<bool> updateEmail(String newEmail) async {
    if (newEmail.isEmpty || newEmail == _user?.email) {
      _isEditingEmail = false;
      notifyListeners();
      return false;
    }

    try {
      _setLoading(true);
      bool success = await _userService.updateUserProfile({"email": newEmail});

      if (success) {
        if (_user != null) {
          _user = UserModel(
            uid: _user!.uid,
            presence: _user!.presence,
            nom: _user!.nom,
            email: newEmail,
            photo: _user!.photo,
            groupes: _user!.groupes,
            stories: _user!.stories,
            archives: _user!.archives,
          );
        }
        _isEditingEmail = false;

        loadUser();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'email: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Changement de mot de passe
  Future<String?> changePassword() async {
    String oldPassword = oldPasswordController.text.trim();
    String newPassword = newPasswordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      return 'Veuillez remplir tous les champs';
    }

    if (newPassword != confirmPassword) {
      return 'Les nouveaux mots de passe ne correspondent pas';
    }

    if (newPassword.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }

    try {
      _setLoading(true);
      bool success =
          await _userService.updatePassword(oldPassword, newPassword);

      if (success) {
        oldPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        _showPasswordFields = false;
        notifyListeners();
        return null; // Succès
      } else {
        return 'Mot de passe incorrect';
      }
    } catch (e) {
      return 'Erreur lors du changement de mot de passe';
    } finally {
      _setLoading(false);
    }
  }

  // Déconnexion
  Future<bool> logout() async {
    try {
      bool deconnected = await _userService.logout();

      if (deconnected) {
        _screenManager.clearAll();
        _socketService.disconnect();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      return false;
    }
  }

  // Suppression du compte
  Future<bool> deleteAccount() async {
    try {
      bool success = await _userService.delete();

      if (success) {
        _screenManager.clearAll();
        _socketService.disconnect();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la suppression du compte: $e');
      return false;
    }
  }

  // Basculer l'édition du nom
  void toggleNameEditing() {
    _isEditingName = !_isEditingName;
    if (!_isEditingName) {
      nameController.text = _user?.nom ?? '';
    }
    notifyListeners();
  }

  // Basculer l'édition de l'email
  void toggleEmailEditing() {
    _isEditingEmail = !_isEditingEmail;
    if (!_isEditingEmail) {
      emailController.text = _user?.email ?? '';
    }
    notifyListeners();
  }

  // Basculer l'affichage des champs de mot de passe
  void togglePasswordFields() {
    _showPasswordFields = !_showPasswordFields;
    if (!_showPasswordFields) {
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    }
    notifyListeners();
  }

  // Méthode privée pour gérer le loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

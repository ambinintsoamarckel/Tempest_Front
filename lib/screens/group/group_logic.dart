import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/group_message.dart';
import '../../services/discu_group_service.dart';

class GroupLogic extends ChangeNotifier {
  final GroupChatService _groupService = GroupChatService();
  final ImagePicker _picker = ImagePicker();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late TextEditingController nameController;
  late TextEditingController descriptionController;

  Group? _group;
  String? _currentUserId;
  bool _isLoading = false;
  bool _isEditingName = false;
  bool _isEditingDescription = false;
  File? _groupPhotoFile;

  // Getters
  Group? get group => _group;
  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;
  bool get isEditingName => _isEditingName;
  bool get isEditingDescription => _isEditingDescription;
  File? get groupPhotoFile => _groupPhotoFile;
  bool get isCreator => _currentUserId == _group?.createur.id;

  GroupLogic(Group initialGroup) {
    _group = initialGroup;
    nameController = TextEditingController(text: _group?.nom);
    descriptionController =
        TextEditingController(text: _group?.description ?? '');
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      String? user = await _storage.read(key: 'user');
      if (user != null) {
        _currentUserId = user.replaceAll('"', '').trim();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de l\'utilisateur: $e');
    }
  }

  void toggleNameEditing() {
    _isEditingName = !_isEditingName;
    notifyListeners();
  }

  void toggleDescriptionEditing() {
    _isEditingDescription = !_isEditingDescription;
    notifyListeners();
  }

  Future<bool> updateGroupName() async {
    if (_group == null) return false;

    String newName = nameController.text.trim();
    if (newName.isEmpty) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final updatedGroup = await _groupService.updateGroup(
        _group!.id,
        {"nom": newName},
      );
      _group = updatedGroup;
      _isEditingName = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du nom: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateGroupDescription() async {
    if (_group == null) return false;

    String newDescription = descriptionController.text.trim();
    if (newDescription.isEmpty) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final updatedGroup = await _groupService.updateGroup(
        _group!.id,
        {"description": newDescription},
      );
      _group = updatedGroup;
      _isEditingDescription = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la description: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> pickAndUpdatePhoto(ImageSource source) async {
    if (_group == null) return false;

    try {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        _groupPhotoFile = File(pickedFile.path);
        notifyListeners();

        _isLoading = true;
        notifyListeners();

        final updatedGroup = await _groupService.changeGroupPhoto(
          _group!.id,
          _groupPhotoFile!.path,
        );

        _group = updatedGroup;
        _groupPhotoFile = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la photo: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Group?> addMember(Group updatedGroup) async {
    _group = updatedGroup;
    notifyListeners();
    return _group;
  }

  Future<bool> removeMember(String memberId) async {
    if (_group == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _groupService.removeMemberFromGroup(_group!.id, memberId);
      _group!.membres.removeWhere((member) => member.id == memberId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du membre: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveGroup() async {
    if (_group == null || _currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _groupService.quitGroup(_group!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la sortie du groupe: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGroup() async {
    if (_group == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _groupService.deleteGroup(_group!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du groupe: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<dynamic> getMembersExceptCurrent() {
    if (_group == null || _currentUserId == null) return [];
    return _group!.membres
        .where((member) => member.id != _currentUserId)
        .toList();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}

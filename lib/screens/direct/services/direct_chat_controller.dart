// lib/screens/direct/services/direct_chat_controller.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mini_social_network/models/direct_message.dart';
import 'package:mini_social_network/models/user.dart';
import 'package:mini_social_network/services/discu_message_service.dart';
import 'package:mini_social_network/utils/file_picker.dart';
import 'package:mini_social_network/services/user_service.dart';
import 'package:mini_social_network/screens/direct/widgets/file_preview.dart';
import 'package:mini_social_network/models/message_content.dart';

class MessageWrapper {
  final DirectMessage message;
  final bool isSending;
  final bool sendFailed;
  final String? tempId;

  MessageWrapper({
    required this.message,
    this.isSending = false,
    this.sendFailed = false,
    this.tempId,
  });
}

class DirectChatController extends ChangeNotifier {
  final String contactId;
  final MessageService messageService = MessageService();
  final List<MessageWrapper> messages = [];
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _audioPath;
  Duration _recordingDuration = Duration.zero;
  File? _previewFile;
  String? _previewType;
  bool _isLoading = true;
  bool _showAttachmentMenu = false;
  User? _currentUser;

  DirectChatController(this.contactId) {
    textController.addListener(notifyListeners);
  }

  // Getters
  bool get isRecording => _isRecording;
  File? get previewFile => _previewFile;
  String? get previewType => _previewType;
  bool get isLoading => _isLoading;
  bool get hasText => textController.text.trim().isNotEmpty;
  bool get showAttachmentMenu => _showAttachmentMenu;
  String? get audioPath => _audioPath;
  Duration get recordingDuration => _recordingDuration;

  void toggleAttachmentMenu() {
    _showAttachmentMenu = !_showAttachmentMenu;
    notifyListeners();
  }

  void closeAttachmentMenu() {
    if (_showAttachmentMenu) {
      _showAttachmentMenu = false;
      notifyListeners();
    }
  }

  Future<void> init() async {
    await _initRecorder();
    await _loadCurrentUser();
    await reload();
    // ✅ SUPPRIMÉ : _scrollToBottom(delayed: true);
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userService = UserService();
      _currentUser = await userService.getCurrentUser();

      if (_currentUser == null) {
        _currentUser = User(
          id: '',
          nom: "Utilisateur",
          email: "email@example.com",
          photo: null,
        );
      }
    } catch (e) {
      print('❌ Erreur chargement user: $e');
    }
  }

  Future<void> reload() async {
    print('🔄 [DirectChat] reload() appelé');

    try {
      _isLoading = true;
      notifyListeners();

      final loaded = await messageService
          .receiveMessagesFromUrl(contactId)
          .timeout(const Duration(seconds: 15),
              onTimeout: () => <DirectMessage>[]);

      print('✅ [DirectChat] Messages reçus: ${loaded.length}');

      final sendingMessages = messages.where((m) => m.isSending).toList();

      messages
        ..clear()
        ..addAll(loaded.map((m) => MessageWrapper(message: m)))
        ..addAll(sendingMessages);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ [DirectChat] Erreur reload: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _silentReload() async {
    try {
      final loaded = await messageService.receiveMessagesFromUrl(contactId);

      final sendingMessages = messages.where((m) => m.isSending).toList();
      messages
        ..clear()
        ..addAll(loaded.map((m) => MessageWrapper(message: m)))
        ..addAll(sendingMessages);

      notifyListeners();
    } catch (e) {
      print('❌ Erreur silent reload: $e');
    }
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  Future<bool> _requestPermissions(List<Permission> perms) async {
    final status = await perms.request();
    return status.values.every((s) => s == PermissionStatus.granted);
  }

  Future<void> pickImage() async {
    closeAttachmentMenu();
    if (!await _requestPermissions([Permission.storage])) return;

    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null) _setPreview(File(file.path), 'image');
    } catch (e) {
      print('❌ Erreur pickImage: $e');
    }
  }

  Future<void> takePhoto() async {
    closeAttachmentMenu();
    if (!await _requestPermissions([Permission.camera])) return;

    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file != null) _setPreview(File(file.path), 'image');
    } catch (e) {
      print('❌ Erreur takePhoto: $e');
    }
  }

  Future<void> pickFile() async {
    closeAttachmentMenu();
    final path = await FilePickerUtil.pickFile();
    if (path != null) {
      final realType = FilePreview.detectFileType(path);
      _setPreview(File(path), realType);
    }
  }

  void _setPreview(File file, String type) {
    _previewFile = file;
    _previewType = type;
    notifyListeners();
  }

  void clearPreview() {
    _previewFile = null;
    _previewType = null;
    notifyListeners();
  }

  void clearAudioPreview() {
    if (_audioPath != null) {
      try {
        File(_audioPath!).delete();
      } catch (e) {
        print('❌ Erreur suppression audio: $e');
      }
    }
    _audioPath = null;
    _recordingDuration = Duration.zero;
    _previewFile = null;
    _previewType = null;
    notifyListeners();
  }

  Future<void> sendText(BuildContext context) async {
    final text = textController.text.trim();
    if (text.isEmpty || _currentUser == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    textController.clear();

    final tempMessage = DirectMessage(
      id: tempId,
      expediteur: _currentUser!,
      destinataire: User(id: contactId, nom: '', email: '', photo: null),
      contenu: MessageContent(type: MessageType.texte, texte: text),
      dateEnvoi: DateTime.now(),
      lu: false,
    );

    messages.add(MessageWrapper(
      message: tempMessage,
      isSending: true,
      tempId: tempId,
    ));
    notifyListeners();
    // ✅ SUPPRIMÉ : _scrollToBottom();

    try {
      await messageService.createMessage(contactId, {"texte": text});

      final index = messages.indexWhere((m) => m.tempId == tempId);
      if (index != -1) {
        messages[index] = MessageWrapper(
          message: tempMessage,
          isSending: false,
          tempId: tempId,
        );
        notifyListeners();
      }

      await Future.delayed(const Duration(milliseconds: 300));
      await _silentReload();
    } catch (e) {
      final index = messages.indexWhere((m) => m.tempId == tempId);
      if (index != -1) {
        messages[index] = MessageWrapper(
          message: tempMessage,
          sendFailed: true,
          tempId: tempId,
        );
        notifyListeners();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Échec de l\'envoi'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () => _retryMessage(tempId, text),
          ),
        ),
      );
    }
  }

  Future<void> _retryMessage(String tempId, String text) async {
    final index = messages.indexWhere((m) => m.tempId == tempId);
    if (index == -1) return;

    messages[index] = MessageWrapper(
      message: messages[index].message,
      isSending: true,
      tempId: tempId,
    );
    notifyListeners();

    try {
      await messageService.createMessage(contactId, {"texte": text});
      messages[index] = MessageWrapper(
        message: messages[index].message,
        isSending: false,
        tempId: tempId,
      );
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));
      await _silentReload();
    } catch (e) {
      messages[index] = MessageWrapper(
        message: messages[index].message,
        sendFailed: true,
        tempId: tempId,
      );
      notifyListeners();
    }
  }

  Future<void> reloadSilently() async {
    await _silentReload();
  }

  Future<void> sendFile(BuildContext context) async {
    if (_previewFile == null || _currentUser == null) return;

    final size = await _previewFile!.length();
    if (size > 50 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichier trop volumineux (max 50MB)')),
      );
      return;
    }

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final file = _previewFile!;
    final type = _previewType!;
    final caption = textController.text.trim();

    clearPreview();
    textController.clear();

    MessageType contentType;
    String? imagePath;
    String? fichierPath;
    String? audioPath;
    String? videoPath;
    String? texte;

    switch (type) {
      case 'image':
        contentType = MessageType.image;
        imagePath = file.path;
        texte = caption.isNotEmpty ? caption : null;
        break;
      case 'audio':
        contentType = MessageType.audio;
        audioPath = file.path;
        break;
      case 'video':
        contentType = MessageType.video;
        videoPath = file.path;
        texte = caption.isNotEmpty ? caption : null;
        break;
      case 'file':
      default:
        contentType = MessageType.fichier;
        fichierPath = file.path;
        break;
    }

    final tempMessage = DirectMessage(
      id: tempId,
      expediteur: _currentUser!,
      destinataire: User(
        id: contactId,
        nom: '',
        email: '',
        photo: null,
      ),
      contenu: MessageContent(
        type: contentType,
        image: imagePath,
        fichier: fichierPath,
        audio: audioPath,
        video: videoPath,
        texte: texte,
      ),
      dateEnvoi: DateTime.now(),
      lu: false,
    );

    messages.add(MessageWrapper(
      message: tempMessage,
      isSending: true,
      tempId: tempId,
    ));
    notifyListeners();
    // ✅ SUPPRIMÉ : _scrollToBottom();

    try {
      final success =
          await messageService.sendFileToPerson(contactId, file.path);

      if (!success) {
        throw Exception('File upload failed');
      }

      final index = messages.indexWhere((m) => m.tempId == tempId);
      if (index != -1) {
        messages[index] = MessageWrapper(
          message: tempMessage,
          isSending: false,
          tempId: tempId,
        );
        notifyListeners();
      }

      await Future.delayed(const Duration(milliseconds: 500));
      await _silentReload();
    } catch (e) {
      print('❌ Erreur sendFile: $e');

      final index = messages.indexWhere((m) => m.tempId == tempId);
      if (index != -1) {
        messages[index] = MessageWrapper(
          message: tempMessage,
          sendFailed: true,
          tempId: tempId,
        );
        notifyListeners();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de l\'envoi du fichier: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () => _retryFileMessage(tempId, file.path, type),
          ),
        ),
      );
    }
  }

  Future<void> _retryFileMessage(
      String tempId, String filePath, String type) async {
    final index = messages.indexWhere((m) => m.tempId == tempId);
    if (index == -1) return;

    messages[index] = MessageWrapper(
      message: messages[index].message,
      isSending: true,
      tempId: tempId,
    );
    notifyListeners();

    try {
      final success =
          await messageService.sendFileToPerson(contactId, filePath);

      if (!success) {
        throw Exception('File upload failed');
      }

      messages[index] = MessageWrapper(
        message: messages[index].message,
        isSending: false,
        tempId: tempId,
      );
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      await _silentReload();
    } catch (e) {
      print('❌ Erreur retry file: $e');

      messages[index] = MessageWrapper(
        message: messages[index].message,
        sendFailed: true,
        tempId: tempId,
      );
      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    if (!await _requestPermissions([Permission.microphone])) return;
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(toFile: path);
    _isRecording = true;
    _audioPath = path;
    _recordingDuration = Duration.zero;
    notifyListeners();
  }

  Future<void> stopRecording() async {
    await _recorder!.stopRecorder();
    _isRecording = false;

    if (_audioPath != null) {
      _setPreview(File(_audioPath!), 'audio');
    }
    notifyListeners();
  }

  Future<void> cancelRecording() async {
    await _recorder!.stopRecorder();
    if (_audioPath != null) {
      try {
        await File(_audioPath!).delete();
      } catch (e) {
        print('❌ Erreur suppression audio: $e');
      }
    }
    _isRecording = false;
    _audioPath = null;
    _recordingDuration = Duration.zero;
    notifyListeners();
  }

  Future<void> sendAudioFromPreview(BuildContext context) async {
    if (_audioPath == null || _currentUser == null) return;

    final audioFile = File(_audioPath!);
    if (!await audioFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichier audio introuvable')),
      );
      return;
    }

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final path = _audioPath!;
    final duration = _recordingDuration;

    _audioPath = null;
    _recordingDuration = Duration.zero;
    notifyListeners();

    final tempMessage = DirectMessage(
      id: tempId,
      expediteur: _currentUser!,
      destinataire: User(
        id: contactId,
        nom: '',
        email: '',
        photo: null,
      ),
      contenu: MessageContent(
        type: MessageType.audio,
        audio: path,
      ),
      dateEnvoi: DateTime.now(),
      lu: false,
    );

    messages.add(MessageWrapper(
      message: tempMessage,
      isSending: true,
      tempId: tempId,
    ));
    notifyListeners();
    // ✅ SUPPRIMÉ : _scrollToBottom();

    try {
      final success = await messageService.sendFileToPerson(contactId, path);

      if (!success) {
        throw Exception('Audio upload failed');
      }

      final index = messages.indexWhere((m) => m.tempId == tempId);
      if (index != -1) {
        messages[index] = MessageWrapper(
          message: tempMessage,
          isSending: false,
          tempId: tempId,
        );
        notifyListeners();
      }

      await Future.delayed(const Duration(milliseconds: 500));
      await _silentReload();
    } catch (e) {
      print('❌ Erreur sendAudio: $e');

      final index = messages.indexWhere((m) => m.tempId == tempId);
      if (index != -1) {
        messages[index] = MessageWrapper(
          message: tempMessage,
          sendFailed: true,
          tempId: tempId,
        );
        notifyListeners();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Échec de l\'envoi de l\'audio'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () => _retryFileMessage(tempId, path, 'audio'),
          ),
        ),
      );
    }
  }

  void cancelAudioPreview() {
    if (_audioPath != null) {
      try {
        File(_audioPath!).delete();
      } catch (e) {
        print('❌ Erreur suppression: $e');
      }
    }
    _audioPath = null;
    _recordingDuration = Duration.zero;
    notifyListeners();
  }

  Future<void> deleteMessage(String messageId) async {
    messages.removeWhere((m) => m.message.id == messageId);
    notifyListeners();

    try {
      await messageService.deleteMessage(messageId);
    } catch (e) {
      await _silentReload();
    }
  }

  // ✅ MÉTHODE COMPLÈTEMENT SUPPRIMÉE
  // void _scrollToBottom({bool delayed = false}) { ... }

  Future<void> reloadFromSocket() async {
    print('🔌 Socket reload dans controller');
    await _silentReload();
    // ✅ SUPPRIMÉ : _scrollToBottom(delayed: true);
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }
}

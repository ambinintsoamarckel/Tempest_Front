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

// ✅ Wrapper pour messages avec état d'envoi
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
  File? _previewFile;
  String? _previewType;
  bool _isLoading = true;
  bool _showAttachmentMenu = false;
  User? _currentUser; // Pour créer les messages temporaires
  int _imagesToLoad = 0; // ✅ Compteur d'images à charger
  int _imagesLoaded = 0; // ✅ Compteur d'images chargées

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

  // ✅ Notifie qu'une image est chargée
  void onImageLoaded() {
    _imagesLoaded++;
    if (_imagesLoaded >= _imagesToLoad && _imagesToLoad > 0) {
      // Toutes les images sont chargées, scroll maintenant
      _scrollToBottom();
    }
  }

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
    _scrollToBottom(delayed: true); // ✅ Scroll initial avec délai
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Récupère l'utilisateur actuel depuis le service
      final msgs = await messageService.receiveMessagesFromUrl(contactId);
      if (msgs.isNotEmpty) {
        // ✅ L'utilisateur actuel est celui qui N'EST PAS le contact
        _currentUser = msgs[0].expediteur.id == contactId
            ? msgs[0].destinataire
            : msgs[0].expediteur;
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

      // Garde les messages en cours d'envoi
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

      // Remplace uniquement les messages non-temporaires
      final sendingMessages = messages.where((m) => m.isSending).toList();
      messages
        ..clear()
        ..addAll(loaded.map((m) => MessageWrapper(message: m)))
        ..addAll(sendingMessages);
      print('Socket reloaded notify Litsenner direct chat screen');

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
    if (path != null) _setPreview(File(path), 'file');
  }

  void _setPreview(File file, String type) {
    _previewFile = file;
    _previewType = type;
    notifyListeners();
  }

  void clearPreview() {
    _previewFile = null;
    _previewType = null;
    _audioPath = null;
    notifyListeners();
  }

  // ✅ Envoi de texte optimiste
  Future<void> sendText(BuildContext context) async {
    final text = textController.text.trim();
    if (text.isEmpty || _currentUser == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    textController.clear();

    // Crée message temporaire
    final tempMessage = DirectMessage(
      id: tempId,
      expediteur: _currentUser!, // ✅ Vous êtes l'expéditeur
      destinataire: User(
          id: contactId,
          nom: '',
          email: '',
          photo: null), // ✅ Contact est le destinataire
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
    _scrollToBottom();

    try {
      await messageService.createMessage(contactId, {"texte": text});

      // Marque comme envoyé
      final index = messages.indexWhere((m) => m.tempId == tempId);
      if (index != -1) {
        messages[index] = MessageWrapper(
          message: tempMessage,
          isSending: false,
          tempId: tempId,
        );
        notifyListeners();
      }

      // Reload silencieux après 300ms
      await Future.delayed(const Duration(milliseconds: 300));
      await _silentReload();
    } catch (e) {
      // Marque comme échoué
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

  // ✅ Envoi de fichier optimiste
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

    clearPreview();

    // Crée message temporaire
    final contentType =
        type == 'image' ? MessageType.image : MessageType.fichier;
    final tempMessage = DirectMessage(
      id: tempId,
      expediteur: _currentUser!, // ✅ Vous êtes l'expéditeur
      destinataire: User(
          id: contactId,
          nom: '',
          email: '',
          photo: null), // ✅ Contact est le destinataire
      contenu: MessageContent(
        type: contentType,
        image: type == 'image' ? file.path : null,
        fichier: type != 'image' ? file.path : null,
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
    _scrollToBottom();

    try {
      await messageService.sendFileToPerson(contactId, file.path);

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
        const SnackBar(
          content: Text('Échec de l\'envoi du fichier'),
          backgroundColor: Colors.red,
        ),
      );
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
    notifyListeners();
  }

  Future<void> stopRecording() async {
    await _recorder!.stopRecorder();
    _isRecording = false;
    if (_audioPath != null) _setPreview(File(_audioPath!), 'audio');
    notifyListeners();
  }

  Future<void> cancelRecording() async {
    await _recorder!.stopRecorder();
    if (_audioPath != null) await File(_audioPath!).delete();
    _isRecording = false;
    _audioPath = null;
    notifyListeners();
  }

  // ✅ Suppression optimiste
  Future<void> deleteMessage(String messageId) async {
    messages.removeWhere((m) => m.message.id == messageId);
    notifyListeners();

    try {
      await messageService.deleteMessage(messageId);
    } catch (e) {
      await _silentReload();
    }
  }

  // ✅ Scroll amélioré avec délai pour attendre le chargement des images
  void _scrollToBottom({bool delayed = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        if (delayed) {
          // Attends que les images se chargent (500ms)
          Future.delayed(const Duration(milliseconds: 500), () {
            if (scrollController.hasClients) {
              scrollController
                  .jumpTo(scrollController.position.maxScrollExtent);
            }
          });
        } else {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  // ✅ Méthode publique pour reload depuis socket
  Future<void> reloadFromSocket() async {
    print('Socket reloaded zay vô tena controller direct chat screen');
    await _silentReload();
    _scrollToBottom(delayed: true); // Scroll avec délai pour les images
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }
}

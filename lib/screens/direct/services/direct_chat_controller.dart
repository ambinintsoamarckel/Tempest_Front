// lib/screens/direct/services/direct_chat_controller.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mini_social_network/models/direct_message.dart';
import 'package:mini_social_network/services/discu_message_service.dart';
import 'package:mini_social_network/utils/file_picker.dart';
import 'package:mini_social_network/theme/app_theme.dart';

// ✅ Modèle pour message temporaire avec état d'envoi
class OptimisticMessage {
  final String tempId;
  final DirectMessage? realMessage;
  final String? text;
  final File? file;
  final String? fileType;
  MessageSendStatus status;
  double? uploadProgress;

  OptimisticMessage({
    required this.tempId,
    this.realMessage,
    this.text,
    this.file,
    this.fileType,
    this.status = MessageSendStatus.sending,
    this.uploadProgress,
  });

  bool get isSending => status == MessageSendStatus.sending;
  bool get isFailed => status == MessageSendStatus.failed;
  bool get isSent => status == MessageSendStatus.sent;
}

enum MessageSendStatus { sending, sent, failed }

class DirectChatController extends ChangeNotifier {
  final String contactId;
  final MessageService messageService = MessageService();
  final List<DirectMessage> messages = [];
  final Map<String, OptimisticMessage> _optimisticMessages = {};
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _audioPath;
  File? _previewFile;
  String? _previewType;
  bool _isLoading = true;
  bool _showAttachmentMenu = false;

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

  // ✅ Messages combinés (réels + optimistes)
  List<dynamic> get allMessages {
    final combined = <dynamic>[...messages];
    combined.addAll(_optimisticMessages.values);
    combined.sort((a, b) {
      final dateA = a is DirectMessage ? a.dateEnvoi : DateTime.now();
      final dateB = b is DirectMessage ? b.dateEnvoi : DateTime.now();
      return dateA.compareTo(dateB);
    });
    return combined;
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
    await reload();
  }

  Future<void> reload() async {
    print('🔄 [DirectChat] reload() appelé pour contactId: $contactId');

    try {
      _isLoading = true;
      notifyListeners();

      final loaded = await messageService
          .receiveMessagesFromUrl(contactId)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        print('⏰ [DirectChat] Timeout API !');
        return <DirectMessage>[];
      });

      print('✅ [DirectChat] Messages reçus: ${loaded.length}');

      messages
        ..clear()
        ..addAll(loaded);

      _isLoading = false;
      notifyListeners();
      print('✅ [DirectChat] reload() terminé');
    } catch (e, s) {
      print('❌ [DirectChat] Erreur reload(): $e');
      print(s);
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Reload silencieux (sans loading, en arrière-plan)
  Future<void> _silentReload() async {
    try {
      final loaded = await messageService.receiveMessagesFromUrl(contactId);
      messages
        ..clear()
        ..addAll(loaded);
      notifyListeners();
    } catch (e) {
      print('❌ [DirectChat] Erreur silent reload: $e');
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
    closeAttachmentMenu(); // ✅ Ferme le menu
    if (!await _requestPermissions([Permission.storage])) return;

    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compression pour éviter crash
      );
      if (file != null) _setPreview(File(file.path), 'image');
    } catch (e) {
      print('❌ Erreur pickImage: $e');
    }
  }

  Future<void> takePhoto() async {
    closeAttachmentMenu(); // ✅ Ferme le menu
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
    closeAttachmentMenu(); // ✅ Ferme le menu
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

  // ✅ Envoi de texte optimiste (style WhatsApp)
  Future<void> sendText(BuildContext context) async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    textController.clear();

    // Ajoute message optimiste immédiatement
    _optimisticMessages[tempId] = OptimisticMessage(
      tempId: tempId,
      text: text,
      status: MessageSendStatus.sending,
    );
    notifyListeners();
    _scrollToBottom();

    try {
      await messageService.createMessage(contactId, {"texte": text});

      // Marque comme envoyé
      _optimisticMessages[tempId]?.status = MessageSendStatus.sent;
      notifyListeners();

      // Reload silencieux après 500ms pour récupérer le vrai message
      await Future.delayed(const Duration(milliseconds: 500));
      await _silentReload();
      _optimisticMessages.remove(tempId);
      notifyListeners();
    } catch (e) {
      // Marque comme échoué
      _optimisticMessages[tempId]?.status = MessageSendStatus.failed;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Échec de l\'envoi. Appuyez pour réessayer.')
          ]),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () => _retrySendText(tempId, text),
          ),
        ),
      );
    }
  }

  Future<void> _retrySendText(String tempId, String text) async {
    _optimisticMessages[tempId]?.status = MessageSendStatus.sending;
    notifyListeners();

    try {
      await messageService.createMessage(contactId, {"texte": text});
      _optimisticMessages[tempId]?.status = MessageSendStatus.sent;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      await _silentReload();
      _optimisticMessages.remove(tempId);
      notifyListeners();
    } catch (e) {
      _optimisticMessages[tempId]?.status = MessageSendStatus.failed;
      notifyListeners();
    }
  }

  // ✅ Envoi de fichier optimiste avec progression
  Future<void> sendFile(BuildContext context) async {
    if (_previewFile == null) return;

    final size = await _previewFile!.length();
    if (size > 50 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichier trop volumineux (max 50MB)')),
      );
      return;
    }

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final file = _previewFile!;
    final type = _previewType!;

    clearPreview();

    // Ajoute fichier optimiste avec progression
    _optimisticMessages[tempId] = OptimisticMessage(
      tempId: tempId,
      file: file,
      fileType: type,
      status: MessageSendStatus.sending,
      uploadProgress: 0.0,
    );
    notifyListeners();
    _scrollToBottom();

    try {
      // Simulation progression (remplacer par vraie progression si API le supporte)
      _simulateUploadProgress(tempId);

      await messageService.sendFileToPerson(contactId, file.path);

      _optimisticMessages[tempId]?.status = MessageSendStatus.sent;
      _optimisticMessages[tempId]?.uploadProgress = 1.0;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      await _silentReload();
      _optimisticMessages.remove(tempId);
      notifyListeners();
    } catch (e) {
      _optimisticMessages[tempId]?.status = MessageSendStatus.failed;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Échec de l\'envoi du fichier'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            onPressed: () => _retrySendFile(tempId, file),
          ),
        ),
      );
    }
  }

  Future<void> _retrySendFile(String tempId, File file) async {
    _optimisticMessages[tempId]?.status = MessageSendStatus.sending;
    _optimisticMessages[tempId]?.uploadProgress = 0.0;
    notifyListeners();

    try {
      _simulateUploadProgress(tempId);
      await messageService.sendFileToPerson(contactId, file.path);

      _optimisticMessages[tempId]?.status = MessageSendStatus.sent;
      _optimisticMessages[tempId]?.uploadProgress = 1.0;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      await _silentReload();
      _optimisticMessages.remove(tempId);
      notifyListeners();
    } catch (e) {
      _optimisticMessages[tempId]?.status = MessageSendStatus.failed;
      notifyListeners();
    }
  }

  void _simulateUploadProgress(String tempId) {
    double progress = 0.0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      progress += 0.1;
      final msg = _optimisticMessages[tempId];
      if (msg == null || msg.status != MessageSendStatus.sending) {
        timer.cancel();
        return;
      }
      msg.uploadProgress = progress.clamp(0.0, 0.95);
      notifyListeners();
    });
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
    // Retire immédiatement de la liste
    messages.removeWhere((m) => m.id == messageId);
    notifyListeners();

    try {
      await messageService.deleteMessage(messageId);
      // Pas de reload nécessaire
    } catch (e) {
      // En cas d'erreur, reload pour restaurer
      await _silentReload();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }
}

// lib/screens/chat/services/base_chat_controller.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mini_social_network/models/user.dart';
import 'package:mini_social_network/models/message_content.dart';
import 'package:mini_social_network/services/user_service.dart';
import 'package:mini_social_network/screens/direct/widgets/file_preview.dart';
import 'package:mini_social_network/utils/discu_file_picker.dart';

/// Classe abstraite de base pour tous les controllers de chat
/// TMessage: Type de message (DirectMessage, GroupMessage, etc.)
/// TWrapper: Type de wrapper (MessageWrapper, GroupMessageWrapper, etc.)
abstract class BaseChatController<TMessage, TWrapper> extends ChangeNotifier {
  // ========== Propriétés communes ==========
  final List<TWrapper> messages = [];
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

  BaseChatController() {
    textController.addListener(notifyListeners);
  }

  // ========== Getters communs ==========
  bool get isRecording => _isRecording;
  File? get previewFile => _previewFile;
  String? get previewType => _previewType;
  bool get isLoading => _isLoading;
  bool get hasText => textController.text.trim().isNotEmpty;
  bool get showAttachmentMenu => _showAttachmentMenu;
  String? get audioPath => _audioPath;
  Duration get recordingDuration => _recordingDuration;
  User? get currentUser => _currentUser;

  // ========== Méthodes abstraites (à implémenter par les enfants) ==========

  /// Récupère les messages depuis le service
  Future<List<TMessage>> fetchMessagesFromService();

  /// Crée un wrapper autour d'un message
  TWrapper wrapMessage(
    TMessage message, {
    bool isSending = false,
    bool sendFailed = false,
    String? tempId,
  });

  /// Crée un message temporaire pour l'affichage optimiste
  TMessage createTempMessage({
    required String tempId,
    required MessageContent content,
    required User expediteur,
  });

  /// Envoie un message texte au serveur
  Future<bool> sendTextToServer(Map<String, dynamic> data);

  /// Envoie un fichier au serveur
  Future<bool> sendFileToServer(String filePath);

  /// Supprime un message du serveur
  Future<void> deleteMessageFromServer(String messageId);

  /// Retourne l'identifiant du destinataire (contactId ou groupId)
  String getRecipientId();

  // ========== Méthodes communes concrètes ==========

  /// Initialisation du controller
  Future<void> init() async {
    print('🟢 [BaseChatController] init() - recipient: ${getRecipientId()}');
    await _initRecorder();
    await _loadCurrentUser();
    await reload();
  }

  /// Charge l'utilisateur courant
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
      print('✅ [BaseChatController] User chargé: ${_currentUser!.nom}');
    } catch (e) {
      print('❌ [BaseChatController] Erreur chargement user: $e');
    }
  }

  /// Recharge les messages avec loader visible
  Future<void> reload() async {
    print('🔄 [BaseChatController] reload() appelé');

    try {
      _isLoading = true;
      notifyListeners();

      final loaded = await fetchMessagesFromService()
          .timeout(const Duration(seconds: 15), onTimeout: () => <TMessage>[]);

      print('✅ [BaseChatController] Messages reçus: ${loaded.length}');

      // Garde les messages en cours d'envoi
      final sendingMessages =
          messages.where((m) => isMessageSending(m)).toList();

      messages
        ..clear()
        ..addAll(loaded.map((m) => wrapMessage(m)))
        ..addAll(sendingMessages);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ [BaseChatController] Erreur reload: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge les messages silencieusement (sans loader)
  Future<void> silentReload() async {
    print('🔇 [BaseChatController] silentReload() appelé');
    try {
      final loaded = await fetchMessagesFromService();

      // Garde les messages en cours d'envoi
      final sendingMessages =
          messages.where((m) => isMessageSending(m)).toList();

      messages
        ..clear()
        ..addAll(loaded.map((m) => wrapMessage(m)))
        ..addAll(sendingMessages);

      notifyListeners();
    } catch (e) {
      print('❌ [BaseChatController] Erreur silent reload: $e');
    }
  }

  /// Initialise l'enregistreur audio
  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  /// Demande des permissions avec vérification du statut
  Future<bool> _requestPermissions(List<Permission> perms) async {
    try {
      // Vérifier d'abord si les permissions sont déjà accordées
      bool allGranted = true;
      for (var perm in perms) {
        final status = await perm.status;
        if (!status.isGranted) {
          allGranted = false;
          break;
        }
      }

      if (allGranted) return true;

      // Demander les permissions
      final statuses = await perms.request();

      // Vérifier si toutes sont accordées
      for (var status in statuses.values) {
        if (!status.isGranted) {
          print('⚠️ [BaseChatController] Permission refusée: $status');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('❌ [BaseChatController] Erreur permissions: $e');
      return false;
    }
  }

  // ========== Gestion des fichiers/médias ==========

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

  Future<void> pickImage() async {
    closeAttachmentMenu();

    // Demander la permission de stockage/photos
    final permission = Platform.isAndroid
        ? (await Permission.photos.status.isDenied
            ? Permission.photos
            : Permission.storage)
        : Permission.photos;

    if (!await _requestPermissions([permission])) {
      print('⚠️ [BaseChatController] Permission galerie refusée');
      return;
    }

    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null) _setPreview(File(file.path), 'image');
    } catch (e) {
      print('❌ [BaseChatController] Erreur pickImage: $e');
    }
  }

  Future<void> takePhoto() async {
    closeAttachmentMenu();

    // Demander UNIQUEMENT la permission caméra
    if (!await _requestPermissions([Permission.camera])) {
      print('⚠️ [BaseChatController] Permission caméra refusée');
      return;
    }

    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file != null) {
        print('✅ [BaseChatController] Photo prise: ${file.path}');
        _setPreview(File(file.path), 'image');
      }
    } catch (e) {
      print('❌ [BaseChatController] Erreur takePhoto: $e');
    }
  }

  Future<void> pickFile() async {
    closeAttachmentMenu();

    // Demander la permission de stockage
    final permission =
        Platform.isAndroid ? Permission.storage : Permission.photos;

    if (!await _requestPermissions([permission])) {
      print('⚠️ [BaseChatController] Permission fichiers refusée');
      return;
    }

    try {
      final path = await FilePickerUtil.pickFile();
      if (path != null) {
        final realType = FilePreview.detectFileType(path);
        _setPreview(File(path), realType);
      }
    } catch (e) {
      print('❌ [BaseChatController] Erreur pickFile: $e');
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
        print('❌ [BaseChatController] Erreur suppression audio: $e');
      }
    }
    _audioPath = null;
    _recordingDuration = Duration.zero;
    _previewFile = null;
    _previewType = null;
    notifyListeners();
  }

  // ========== Gestion de l'enregistrement audio ==========

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
        print('❌ [BaseChatController] Erreur suppression audio: $e');
      }
    }
    _isRecording = false;
    _audioPath = null;
    _recordingDuration = Duration.zero;
    notifyListeners();
  }

  void cancelAudioPreview() {
    if (_audioPath != null) {
      try {
        File(_audioPath!).delete();
      } catch (e) {
        print('❌ [BaseChatController] Erreur suppression: $e');
      }
    }
    _audioPath = null;
    _recordingDuration = Duration.zero;
    notifyListeners();
  }

  // ========== Envoi de messages ==========

  Future<void> sendText(BuildContext context) async {
    final text = textController.text.trim();
    if (text.isEmpty || _currentUser == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    textController.clear();

    final tempMessage = createTempMessage(
      tempId: tempId,
      content: MessageContent(type: MessageType.texte, texte: text),
      expediteur: _currentUser!,
    );

    messages.add(wrapMessage(
      tempMessage,
      isSending: true,
      tempId: tempId,
    ));
    notifyListeners();

    try {
      final success = await sendTextToServer({"texte": text});

      if (!success) throw Exception('Send failed');

      // ✅ FIX: Trouve le wrapper et récupère son message
      final index = messages.indexWhere((m) => getTempId(m) == tempId);
      if (index != -1) {
        final existingMessage = getMessageFromWrapper(messages[index]);
        messages[index] = wrapMessage(
          existingMessage, // ✅ Utilise le message du wrapper existant
          isSending: false,
          tempId: tempId,
        );
        notifyListeners();
      }

      await Future.delayed(const Duration(milliseconds: 300));
      await silentReload();
    } catch (e) {
      print('❌ [BaseChatController] Erreur sendText: $e');

      final index = messages.indexWhere((m) => getTempId(m) == tempId);
      if (index != -1) {
        final existingMessage = getMessageFromWrapper(messages[index]);
        messages[index] = wrapMessage(
          existingMessage, // ✅ Utilise le message du wrapper existant
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
            onPressed: () => _retryTextMessage(tempId, text),
          ),
        ),
      );
    }
  }

  Future<void> _retryTextMessage(String tempId, String text) async {
    final index = messages.indexWhere((m) => getTempId(m) == tempId);
    if (index == -1) return;

    messages[index] = wrapMessage(
      getMessageFromWrapper(messages[index]),
      isSending: true,
      tempId: tempId,
    );
    notifyListeners();

    try {
      final success = await sendTextToServer({"texte": text});
      if (!success) throw Exception('Send failed');

      messages[index] = wrapMessage(
        getMessageFromWrapper(messages[index]),
        isSending: false,
        tempId: tempId,
      );
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));
      await silentReload();
    } catch (e) {
      print('❌ [BaseChatController] Erreur retry message: $e');
      messages[index] = wrapMessage(
        getMessageFromWrapper(messages[index]),
        sendFailed: true,
        tempId: tempId,
      );
      notifyListeners();
    }
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

    clearPreview();
    textController.clear();

    MessageType contentType;
    String? imagePath;
    String? fichierPath;
    String? audioPath;
    String? videoPath;

    switch (type) {
      case 'image':
        contentType = MessageType.image;
        imagePath = file.path;
        break;
      case 'audio':
        contentType = MessageType.audio;
        audioPath = file.path;
        break;
      case 'video':
        contentType = MessageType.video;
        videoPath = file.path;
        break;
      case 'file':
      default:
        contentType = MessageType.fichier;
        fichierPath = file.path;
        break;
    }

    final tempMessage = createTempMessage(
      tempId: tempId,
      content: MessageContent(
        type: contentType,
        image: imagePath,
        fichier: fichierPath,
        audio: audioPath,
        video: videoPath,
        texte: null,
      ),
      expediteur: _currentUser!,
    );

    messages.add(wrapMessage(
      tempMessage,
      isSending: true,
      tempId: tempId,
    ));
    notifyListeners();

    try {
      final success = await sendFileToServer(file.path);

      if (!success) throw Exception('File upload failed');

      // ✅ FIX: Utilise le message du wrapper existant
      final index = messages.indexWhere((m) => getTempId(m) == tempId);
      if (index != -1) {
        final existingMessage = getMessageFromWrapper(messages[index]);
        messages[index] = wrapMessage(
          existingMessage,
          isSending: false,
          tempId: tempId,
        );
        notifyListeners();
      }

      await Future.delayed(const Duration(milliseconds: 500));
      await silentReload();
    } catch (e) {
      print('❌ [BaseChatController] Erreur sendFile: $e');

      final index = messages.indexWhere((m) => getTempId(m) == tempId);
      if (index != -1) {
        final existingMessage = getMessageFromWrapper(messages[index]);
        messages[index] = wrapMessage(
          existingMessage,
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
            onPressed: () => _retryFileMessage(tempId, file.path),
          ),
        ),
      );
    }
  }

  Future<void> _retryFileMessage(String tempId, String filePath) async {
    final index = messages.indexWhere((m) => getTempId(m) == tempId);
    if (index == -1) return;

    messages[index] = wrapMessage(
      getMessageFromWrapper(messages[index]),
      isSending: true,
      tempId: tempId,
    );
    notifyListeners();

    try {
      final success = await sendFileToServer(filePath);

      if (!success) throw Exception('File upload failed');

      messages[index] = wrapMessage(
        getMessageFromWrapper(messages[index]),
        isSending: false,
        tempId: tempId,
      );
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      await silentReload();
    } catch (e) {
      print('❌ [BaseChatController] Erreur retry file: $e');

      messages[index] = wrapMessage(
        getMessageFromWrapper(messages[index]),
        sendFailed: true,
        tempId: tempId,
      );
      notifyListeners();
    }
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

    _audioPath = null;
    _recordingDuration = Duration.zero;
    notifyListeners();

    final tempMessage = createTempMessage(
      tempId: tempId,
      content: MessageContent(type: MessageType.audio, audio: path),
      expediteur: _currentUser!,
    );

    messages.add(wrapMessage(
      tempMessage,
      isSending: true,
      tempId: tempId,
    ));
    notifyListeners();

    try {
      final success = await sendFileToServer(path);

      if (!success) throw Exception('Audio upload failed');

      // ✅ FIX: Utilise le message du wrapper existant
      final index = messages.indexWhere((m) => getTempId(m) == tempId);
      if (index != -1) {
        final existingMessage = getMessageFromWrapper(messages[index]);
        messages[index] = wrapMessage(
          existingMessage,
          isSending: false,
          tempId: tempId,
        );
        notifyListeners();
      }

      await Future.delayed(const Duration(milliseconds: 500));
      await silentReload();
    } catch (e) {
      print('❌ [BaseChatController] Erreur sendAudio: $e');

      final index = messages.indexWhere((m) => getTempId(m) == tempId);
      if (index != -1) {
        final existingMessage = getMessageFromWrapper(messages[index]);
        messages[index] = wrapMessage(
          existingMessage,
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
            onPressed: () => _retryFileMessage(tempId, path),
          ),
        ),
      );
    }
  }

  // ========== Autres opérations ==========

  Future<void> deleteMessage(String messageId) async {
    messages.removeWhere((m) => getMessageId(m) == messageId);
    notifyListeners();

    try {
      await deleteMessageFromServer(messageId);
    } catch (e) {
      print('❌ [BaseChatController] Erreur deleteMessage: $e');
      await silentReload();
    }
  }

  Future<void> reloadFromSocket() async {
    print('🔌 [BaseChatController] Socket reload');
    await silentReload();
  }

  Future<void> reloadSilently() async {
    await silentReload();
  }

  // ========== Méthodes utilitaires abstraites ==========
  // Ces méthodes permettent d'accéder aux propriétés du wrapper de manière générique

  String? getTempId(TWrapper wrapper);
  bool isMessageSending(TWrapper wrapper);
  TMessage getMessageFromWrapper(TWrapper wrapper);
  String getMessageId(TWrapper wrapper);

  @override
  void dispose() {
    print('🔴 [BaseChatController] dispose()');
    textController.dispose();
    scrollController.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }
}

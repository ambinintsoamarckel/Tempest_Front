import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../models/direct_message.dart';
import '../widgets/messages/direct_message_widget.dart';
import '../utils/discu_file_picker.dart';
import 'package:intl/intl.dart';
import '../services/discu_message_service.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'ctt_screen.dart';
import 'package:mini_social_network/theme/app_theme.dart';
import '../widgets/voice_recording_widget.dart';

class DirectChatScreen extends StatefulWidget {
  final String id;
  static final GlobalKey<_DirectChatScreenState> directChatScreenKey =
      GlobalKey<_DirectChatScreenState>();

  DirectChatScreen({required this.id}) : super(key: directChatScreenKey);

  @override
  _DirectChatScreenState createState() => _DirectChatScreenState();

  void reload() {
    final state = directChatScreenKey.currentState;
    if (state != null) {
      state._reload();
    }
  }
}

class _DirectChatScreenState extends State<DirectChatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final List<DirectMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final MessageService _messageService = MessageService();
  late Future<User> _contactFuture;
  final CurrentScreenManager screenManager = CurrentScreenManager();
  DateTime? _previousMessageDate;
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _audioPath;
  final ScrollController _scrollController = ScrollController();
  File? _previewFile;
  String? _previewType;
  bool _showAttachmentMenu = false;
  late AnimationController _attachmentAnimationController;
  late Animation<double> _attachmentAnimation;
  bool _isSending = false;
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _contactFuture = _loadContact();
    screenManager.updateCurrentScreen('directChat');
    _initRecorder();

    _attachmentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _attachmentAnimation = CurvedAnimation(
      parent: _attachmentAnimationController,
      curve: Curves.easeInOut,
    );

    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _scrollController.dispose();
    _recorder?.closeRecorder();
    _attachmentAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Remettre l'écran actuel quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed) {
      screenManager.updateCurrentScreen('directChat');
    }
  }

  Future<void> _reload() async {
    try {
      List<DirectMessage> messages =
          await _messageService.receiveMessagesFromUrl(widget.id);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _isLoadingInitial = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToEnd();
        });
      }
    } catch (e) {
      print('Failed to load messages: $e');
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
        });
      }
    }
  }

  Future<User> _loadContact() async {
    try {
      List<DirectMessage> messages =
          await _messageService.receiveMessagesFromUrl(widget.id);
      if (mounted) {
        setState(() {
          _messages.addAll(messages);
          _isLoadingInitial = false;
        });
        _scrollToEnd();
      }
      return messages.isNotEmpty && messages[0].expediteur.id == widget.id
          ? messages[0].expediteur
          : messages[0].destinataire;
    } catch (e) {
      print('Failed to load messages: $e');
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
        });
      }
      return User(
          id: widget.id,
          nom: "Nouveau contact",
          email: "email@example.com",
          photo: null,
          presence: 'inactif');
    }
  }

  Future<bool> _requestPermissions() async {
    final List<Permission> permissions = [
      Permission.camera,
      Permission.storage
    ];
    Map<Permission, PermissionStatus> permissionStatus =
        await permissions.request();
    return permissionStatus[Permission.camera] == PermissionStatus.granted &&
        permissionStatus[Permission.storage] == PermissionStatus.granted;
  }

  Future<bool> _requestRecorderPermissions() async {
    final List<Permission> permissions = [
      Permission.microphone,
      Permission.storage
    ];
    Map<Permission, PermissionStatus> permissionStatus =
        await permissions.request();
    return permissionStatus[Permission.microphone] ==
            PermissionStatus.granted &&
        permissionStatus[Permission.storage] == PermissionStatus.granted;
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = !_showAttachmentMenu;
      if (_showAttachmentMenu) {
        _attachmentAnimationController.forward();
      } else {
        _attachmentAnimationController.reverse();
      }
    });
  }

  Future<void> _pickImage(User contact) async {
    _toggleAttachmentMenu();
    final bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      _showErrorSnackBar('Permissions non accordées');
      return;
    }

    // S'assurer qu'on reste sur cet écran
    screenManager.updateCurrentScreen('directChat');

    final XFile? pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    // Vérifier qu'on est toujours sur cet écran après la sélection
    if (pickedImage != null && mounted) {
      setState(() {
        _previewFile = File(pickedImage.path);
        _previewType = 'image';
      });
      _scrollToEnd();
    }
  }

  Future<void> _pickFileAndSend(User contact) async {
    _toggleAttachmentMenu();
    try {
      screenManager.updateCurrentScreen('directChat');

      String? filePath = await FilePickerUtil.pickFile();

      if (filePath != null && mounted) {
        setState(() {
          _previewFile = File(filePath);
          _previewType = 'file';
        });
        _scrollToEnd();
      }
    } catch (e) {
      _showErrorSnackBar('Échec de la sélection du fichier: $e');
    }
  }

  Future<void> _takePhoto(User contact) async {
    _toggleAttachmentMenu();
    final bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      _showErrorSnackBar('Permissions non accordées');
      return;
    }

    // S'assurer qu'on reste sur cet écran
    screenManager.updateCurrentScreen('directChat');

    final XFile? pickedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);

    // Vérifier qu'on est toujours sur cet écran après la photo
    if (pickedImage != null && mounted) {
      setState(() {
        _previewFile = File(pickedImage.path);
        _previewType = 'image';
      });
      _scrollToEnd();
    }
  }

  void _handleSubmitted(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _isSending) return;

    FocusScope.of(context).unfocus();
    _textController.clear();

    setState(() {
      _isSending = true;
    });

    // Afficher un indicateur de progression
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Envoi en cours...'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      bool? createdMessage = await _messageService
          .createMessage(widget.id, {"texte": trimmedText});

      if (mounted) {
        messenger.hideCurrentSnackBar();

        if (createdMessage != null) {
          await _reload();
          _scrollToEnd();

          messenger.showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Message envoyé'),
                ],
              ),
              backgroundColor: AppTheme.secondaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          _showErrorSnackBar('Échec de l\'envoi du message.');
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        messenger.hideCurrentSnackBar();
        _showErrorSnackBar('Échec de l\'envoi du message : $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatFullDate(DateTime date) {
    return DateFormat('EEEE d MMMM y', 'fr_FR').format(date);
  }

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    final difference = nowDate.difference(messageDate).inDays;

    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else {
      return _formatFullDate(messageDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildModernAppBar(),
      body: FutureBuilder<User>(
        future: _contactFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoadingInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorState();
          } else {
            User contact = snapshot.data!;
            return Column(
              children: <Widget>[
                Flexible(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    controller: _scrollController,
                    addAutomaticKeepAlives: true,
                    cacheExtent: 1000.0,
                    itemBuilder: (_, int index) {
                      DirectMessage message = _messages[index];
                      bool showDate = _shouldShowDate(message.dateEnvoi);
                      _previousMessageDate = message.dateEnvoi;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (showDate) _buildDateBadge(message.dateEnvoi),
                          DirectMessageWidget(
                            key: ValueKey(message.id ?? index),
                            message: _messages[index],
                            contact: contact,
                            onDelete: _deleteMessage,
                            onTransfer: _transferMessage,
                            onCopy: () => _copyMessage(index),
                            previousMessageDate: _previousMessageDate,
                          ),
                        ],
                      );
                    },
                    itemCount: _messages.length,
                  ),
                ),
                if (_previewFile != null) _buildPreviewContainer(contact),
                if (_isRecording)
                  RecordingInterface(
                    onStop: _stopRecording,
                    onCancel: _cancelRecording,
                    showDuration: true,
                  ),
                _buildInputArea(contact),
              ],
            );
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: FutureBuilder<User>(
        future: _contactFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Chargement...');
          } else if (snapshot.hasError) {
            return const Text('Erreur');
          } else {
            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  backgroundImage: snapshot.data?.photo != null
                      ? NetworkImage(snapshot.data!.photo!)
                      : null,
                  child: snapshot.data?.photo == null
                      ? Text(
                          snapshot.data?.nom.substring(0, 1).toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        snapshot.data?.nom ?? 'Chat',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getPresenceColor(
                                  snapshot.data?.presence ?? 'inactif'),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _getPresenceText(
                                  snapshot.data?.presence ?? 'inactif'),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getPresenceColor(
                                    snapshot.data?.presence ?? 'inactif'),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
      actions: [
        ActionIcon(
          icon: Icons.videocam_outlined,
          onPressed: () {},
        ),
        ActionIcon(
          icon: Icons.call_outlined,
          onPressed: () {},
        ),
        ActionIcon(
          icon: Icons.more_vert,
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.accentColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Échec du chargement du chat',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _contactFuture = _loadContact();
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge(DateTime date) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: AppTheme.dateBadgeDecoration(context),
        child: Text(
          _formatMessageDate(date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }

  Widget _buildPreviewContainer(User contact) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.previewContainerDecoration(context),
      child: Row(
        children: [
          _buildPreviewThumbnail(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _previewFile!.path.split('/').last,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: Icons.close,
                      color: AppTheme.accentColor,
                      onPressed: _clearPreview,
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      icon: Icons.send,
                      color: AppTheme.secondaryColor,
                      onPressed: () => _sendPreview(contact),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewThumbnail() {
    if (_previewType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _previewFile!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    } else if (_previewType == 'audio') {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.audiotrack,
          size: 40,
          color: AppTheme.primaryColor,
        ),
      );
    } else {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.insert_drive_file,
          size: 40,
          color: AppTheme.secondaryColor,
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildInputArea(User contact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_showAttachmentMenu) _buildAttachmentMenu(contact),
          Row(
            children: <Widget>[
              ActionIcon(
                icon: _showAttachmentMenu
                    ? Icons.close
                    : Icons.add_circle_outline,
                onPressed: _toggleAttachmentMenu,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2C2C2C)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _handleSubmitted,
                    decoration: const InputDecoration(
                      hintText: "Message",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    maxLines: null,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (_textController.text.trim().isNotEmpty)
                GestureDetector(
                  onTap: () => _handleSubmitted(_textController.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                )
              else
                VoiceRecordingButton(
                  isRecording: _isRecording,
                  onStartRecording: _startRecording,
                  useModernMode: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentMenu(User contact) {
    return FadeTransition(
      opacity: _attachmentAnimation,
      child: SizeTransition(
        sizeFactor: _attachmentAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentOption(
                icon: Icons.photo_library,
                label: 'Galerie',
                color: AppTheme.primaryColor,
                onTap: () => _pickImage(contact),
              ),
              _buildAttachmentOption(
                icon: Icons.camera_alt,
                label: 'Caméra',
                color: AppTheme.secondaryColor,
                onTap: () => _takePhoto(contact),
              ),
              _buildAttachmentOption(
                icon: Icons.insert_drive_file,
                label: 'Fichier',
                color: AppTheme.accentColor,
                onTap: () => _pickFileAndSend(contact),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initRecorder() async {
    try {
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
    } catch (e) {
      print('Failed to initialize recorder: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_recorder == null) {
      _showErrorSnackBar('Enregistreur non initialisé');
      return;
    }

    if (!await _requestRecorderPermissions()) {
      _showErrorSnackBar('Permissions non accordées');
      return;
    }

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String filePath =
          '${appDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder!.startRecorder(toFile: filePath);

      if (mounted) {
        setState(() {
          _isRecording = true;
          _audioPath = filePath;
        });
      }
    } catch (e) {
      print('Failed to start recording: $e');
      _showErrorSnackBar('Échec de l\'enregistrement');
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder == null || !_isRecording) return;

    try {
      await _recorder!.stopRecorder();

      if (mounted) {
        setState(() {
          _isRecording = false;
        });

        if (_audioPath != null) {
          setState(() {
            _previewFile = File(_audioPath!);
            _previewType = 'audio';
          });
          _scrollToEnd();
        }
      }
    } catch (e) {
      print('Failed to stop recording: $e');
      _showErrorSnackBar('Échec de l\'arrêt de l\'enregistrement');
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
    }
  }

  void _cancelRecording() async {
    if (_recorder == null || !_isRecording) return;

    try {
      await _recorder!.stopRecorder();

      if (_audioPath != null) {
        final file = File(_audioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      if (mounted) {
        setState(() {
          _isRecording = false;
          _audioPath = null;
        });
      }
    } catch (e) {
      print('Failed to cancel recording: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _audioPath = null;
        });
      }
    }
  }

  void _clearPreview() {
    setState(() {
      _previewFile = null;
      _previewType = null;
      _audioPath = null;
    });
  }

  Future<void> _sendPreview(User contact) async {
    if (_previewFile == null || _isSending) return;

    setState(() {
      _isSending = true;
    });

    // Vérifier la taille du fichier (limite à 50MB par exemple)
    final fileSize = await _previewFile!.length();
    if (fileSize > 50 * 1024 * 1024) {
      setState(() {
        _isSending = false;
      });
      _showErrorSnackBar('Le fichier est trop volumineux (max 50MB)');
      return;
    }

    _showProgressDialog();

    try {
      print('Envoi du fichier: ${_previewFile!.path}');
      print('Taille: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      print('Type: $_previewType');

      await _messageService.sendFileToPerson(contact.id, _previewFile!.path);

      if (mounted) {
        Navigator.of(context).pop();

        setState(() {
          _previewFile = null;
          _previewType = null;
          _audioPath = null;
          _isSending = false;
        });

        await _reload();
        _scrollToEnd();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Fichier envoyé avec succès'),
              ],
            ),
            backgroundColor: AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('Failed to send file: $e');
      print('Stack trace: ${StackTrace.current}');

      if (mounted) {
        Navigator.of(context).pop();
        setState(() {
          _isSending = false;
        });

        String errorMessage = 'Échec de l\'envoi du fichier';
        if (e.toString().contains('500')) {
          errorMessage =
              'Erreur serveur. Ce type de fichier n\'est peut-être pas supporté.';
        } else if (e.toString().contains('413')) {
          errorMessage = 'Le fichier est trop volumineux';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Délai d\'attente dépassé. Vérifiez votre connexion.';
        }

        _showErrorSnackBar(errorMessage);
      }
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 24),
                Text(
                  "Envoi en cours...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteMessage(String messageId) async {
    try {
      await _messageService.deleteMessage(messageId);
      await _reload();
    } catch (e) {
      print('Failed to delete message: $e');
      _showErrorSnackBar('Échec de la suppression: $e');
    }
  }

  void _transferMessage(String messageId) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ContaScreen(isTransferMode: true, id: messageId),
        ),
      );
      await _reload();
    } catch (e) {
      print('Failed to transfer message: $e');
    }
  }

  Future<void> _copyMessage(int index) async {
    try {
      DirectMessage message = _messages[index];
      String messageContent = message.contenu.texte ?? '';

      if (messageContent.isEmpty) {
        _showErrorSnackBar('Aucun texte à copier');
        return;
      }

      await Clipboard.setData(ClipboardData(text: messageContent));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Message copié'),
              ],
            ),
            backgroundColor: AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('Failed to copy message: $e');
      _showErrorSnackBar('Échec de la copie');
    }
  }

  bool _shouldShowDate(DateTime currentMessageDate) {
    if (_previousMessageDate == null) return true;

    final DateTime previousDate = DateTime(
      _previousMessageDate!.year,
      _previousMessageDate!.month,
      _previousMessageDate!.day,
    );
    final DateTime currentDate = DateTime(
      currentMessageDate.year,
      currentMessageDate.month,
      currentMessageDate.day,
    );

    return currentDate.isAfter(previousDate);
  }

  Color _getPresenceColor(String presence) {
    switch (presence.toLowerCase()) {
      case 'actif':
      case 'en ligne':
        return AppTheme.secondaryColor;
      case 'absent':
      case 'away':
        return Colors.orange;
      case 'ne pas déranger':
      case 'dnd':
        return AppTheme.accentColor;
      default:
        return Colors.grey;
    }
  }

  String _getPresenceText(String presence) {
    switch (presence.toLowerCase()) {
      case 'actif':
      case 'en ligne':
        return 'En ligne';
      case 'absent':
      case 'away':
        return 'Absent';
      case 'ne pas déranger':
      case 'dnd':
        return 'Occupé';
      default:
        return 'Hors ligne';
    }
  }
}

class ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const ActionIcon({
    Key? key,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 22),
      onPressed: onPressed,
      splashRadius: 24,
    );
  }
}


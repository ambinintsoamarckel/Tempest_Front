import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../models/direct_message.dart';
import '../widgets/direct_message_widget.dart';
import '../utils/discu_file_picker.dart';
import 'package:intl/intl.dart';
import '../services/discu_message_service.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/RecordingWidget.dart';

class DirectChatScreen extends StatefulWidget {
  final String id;
  static final GlobalKey<_DirectChatScreenState> directChatScreenKey = GlobalKey<_DirectChatScreenState>();

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

class _DirectChatScreenState extends State<DirectChatScreen> {
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
  String? _previewType; // 'image', 'audio', or 'file'

  Future<void> _reload() async {
    try {
      List<DirectMessage> messages = await _messageService.receiveMessagesFromUrl(widget.id);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToEnd();
      });
    } catch (e) {
      print('Failed to load messages: $e');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    _contactFuture = _loadContact();
    screenManager.updateCurrentScreen('directChat');
    _initRecorder();
  }

  @override
  void dispose() {
    _recorder!.closeRecorder();
    super.dispose();
  }

  Future<User> _loadContact() async {
    try {
      List<DirectMessage> messages = await _messageService.receiveMessagesFromUrl(widget.id);
      setState(() {
        _messages.addAll(messages);
      });
      _scrollToEnd();
      return messages[0].expediteur.id == widget.id ? messages[0].expediteur : messages[0].destinataire;
    } catch (e) {
      print('Failed to load messages: $e');
      return User(id: widget.id, nom: "Nouveau contact", email: "email@example.com", photo: null);
    }
  }

  Future<bool> _requestPermissions() async {
    final List<Permission> permissions = [Permission.camera, Permission.storage];
    Map<Permission, PermissionStatus> permissionStatus = await permissions.request();

    return permissionStatus[Permission.camera] == PermissionStatus.granted &&
        permissionStatus[Permission.storage] == PermissionStatus.granted;
  }

  Future<bool> _requestRecorderPermissions() async {
    final List<Permission> permissions = [Permission.microphone, Permission.storage];
    Map<Permission, PermissionStatus> permissionStatus = await permissions.request();
    return permissionStatus[Permission.microphone] == PermissionStatus.granted &&
        permissionStatus[Permission.storage] == PermissionStatus.granted;
  }

  Future<void> _pickImage(User contact) async {
    final bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      print('Permissions not granted');
      return;
    }

    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _previewFile = File(pickedImage.path);
        _previewType = 'image';
      });
      _scrollToEnd();
    }
  }

  Future<void> _pickFileAndSend(User contact) async {
    try {
      String? filePath = await FilePickerUtil.pickFile();
      if (filePath != null) {
        setState(() {
          _previewFile = File(filePath);
          _previewType = 'file';
        });
        _scrollToEnd();
      }
    } catch (e) {
      print('Failed to pick and send file: $e');
    }
  }

  Future<void> _takePhoto(User contact) async {
    final bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      print('Permissions not granted');
      return;
    }

    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _previewFile = File(pickedImage.path);
        _previewType = 'image';
      });
      _scrollToEnd();
    }
  }

  void _handleSubmitted(String text) async {
    if (text.isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus(); // Fermer le clavier virtuel

    try {
      bool? createdMessage = await _messageService.createMessage(widget.id, {"texte": text});
      if (createdMessage != null) {
        _reload();
        _scrollToEnd();
      } else {
        _showErrorSnackBar('Échec de l\'envoi du message.');
      }
    } catch (e) {
      _showErrorSnackBar('Échec de l\'envoi du message : $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  bool _isLastReadMessageByCurrentUser(int index) {
    if (_messages.isEmpty || index != _messages.length - 1) return false;
    DirectMessage message = _messages[index];
    return message.destinataire.id == widget.id && message.lu;
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: _messages.length),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatFullDate(DateTime date) {
    final DateTime adjustedDate = date;
    return DateFormat('EEEE d MMMM y', 'fr_FR').format(adjustedDate);
  }

  String _formatMessageDate(DateTime date) {
    final DateTime adjustedDate = date;
    final now = DateTime.now();

    final nowDate = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(adjustedDate.year, adjustedDate.month, adjustedDate.day);

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
      appBar: AppBar(
        title: FutureBuilder<User>(
          future: _contactFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            } else if (snapshot.hasError) {
              return const Text('Error');
            } else {
              return Text(snapshot.data?.nom ?? 'Chat');
            }
          },
        ),
      ),
      body: FutureBuilder<User>(
        future: _contactFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Failed to load chat'));
          } else {
            User contact = snapshot.data!;
            return Column(
              children: <Widget>[
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    controller: _scrollController,
                    itemBuilder: (_, int index) {
                      DirectMessage message = _messages[index];
                      bool showDate = _shouldShowDate(message.dateEnvoi);

                      _previousMessageDate = message.dateEnvoi;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (showDate)
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 5.0),
                              child: Text(
                                _formatMessageDate(message.dateEnvoi),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                            ),
                          DirectMessageWidget(
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
                if (_previewFile != null)
                  Container(
                    margin: const EdgeInsets.all(10.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 5.0,
                          spreadRadius: 2.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (_previewType == 'image') ...[
                          Image.file(
                            _previewFile!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 10), // Augmentation de la distance entre le fichier et le nom du fichier
                        ] else if (_previewType == 'audio') ...[
                          const Icon(Icons.audiotrack, size: 100, color: Colors.blue),
                          const SizedBox(width: 20), // Augmentation de la distance entre le fichier et le nom du fichier
                        ] else if (_previewType == 'file') ...[
                          const Icon(Icons.insert_drive_file, size: 95, color: Colors.green),
                          const SizedBox(width: 10), // Augmentation de la distance entre le fichier et le nom du fichier
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _previewFile!.path.split('/').last,
                          
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Center(
                                child: Row (
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: _clearPreview,
                                      child: const Icon(Icons.delete, size: 40, color: Colors.redAccent), // Icône pour annuler avec taille augmentée
                                    ),
                                    const SizedBox(width: 30), // Augmentation de la distance entre les icônes
                                    GestureDetector(
                                      onTap: () => _sendPreview(contact),
                                      child: const Icon(Icons.upload, size: 40, color: Colors.greenAccent), // Icône pour envoyer
                                    ),
                                  ]
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              
                if (_isRecording)
                  const RecordingWidget(),
          
                const Divider(height: 1.0),
                Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: _buildTextComposer(contact),
                   ),
              ],
            );
          }
        },
      ),
    );
  }
        



  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  Future<void> _startRecording() async {
    if (!await _requestRecorderPermissions()) {
      print('Permissions not granted');
      return;
    }

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String filePath = '${appDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(toFile: filePath);
    setState(() {
      _isRecording = true;
      _audioPath = filePath;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
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

  

  void _clearPreview() {
    setState(() {
      _previewFile = null;
      _previewType = null;
    });
  }

Future<void> _sendPreview(User contact) async {
  if (_previewFile == null) return;

  _showProgressDialog();

  try {
    if (_previewType == 'image') {
      await _messageService.sendFileToPerson(contact.id, _previewFile!.path);
    } else if (_previewType == 'audio') {
      await _messageService.sendFileToPerson(contact.id, _previewFile!.path);
    } else if (_previewType == 'file') {
      await _messageService.sendFileToPerson(contact.id, _previewFile!.path);
    }

    setState(() {
      _previewFile = null;
      _previewType = null;
    });

    _reload();
  } catch (e) {
    _showErrorSnackBar('Échec de l\'envoi du fichier : $e');
  } finally {
    Navigator.of(context).pop(); // Ferme la boîte de dialogue de progression
  }
}


void _showProgressDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Envoi en cours..."),
            ],
          ),
        ),
      );
    },
  );
}


  void _deleteMessage(String messageId) async {
    await _messageService.deleteMessage(messageId).catchError((e) {
      print('Failed to delete message: $e');
    }).whenComplete(() {
      _reload();
    });
  }

  void _transferMessage(String messageId) async {
    // Implémentez ici la logique de transfert de message
    print('Message $messageId transféré.');
  }

  Future<void> _copyMessage(int index) async {
    DirectMessage message = _messages[index];
    String messageContent = message.contenu.texte ?? '';

    await Clipboard.setData(ClipboardData(text: messageContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copié dans le presse-papiers'),
      ),
    );
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

  Widget _buildTextComposer(User contact) {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.photo),
              onPressed: () => _pickImage(contact),
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () => _takePhoto(contact),
            ),
            IconButton(
              icon: const Icon(Icons.insert_drive_file),
              onPressed: () => _pickFileAndSend(contact),
            ),
            Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: (text) => _handleSubmitted(text),
              decoration: const InputDecoration.collapsed(
                hintText: "Envoyer un message",
              ),
              maxLines: null, // Permet au texte de se redimensionner automatiquement
              minLines: 1, // Nombre minimum de lignes affichées
            ),
          ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: Icon(
                _isRecording ? Icons.mic_off : Icons.mic,
                color: _isRecording ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

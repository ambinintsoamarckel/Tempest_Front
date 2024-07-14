import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_social_network/models/contact.dart';
import 'package:mini_social_network/screens/contacts_screen.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../models/direct_message.dart';
import '../widgets/direct_message_widget.dart';
import '../utils/discu_file_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/discu_message_service.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/audio_message_player.dart';

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
    _textController.clear();

    FocusScope.of(context).unfocus(); // Fermer le clavier virtuel

    try {
      bool? createdMessage = await _messageService.createMessage(widget.id, {"texte": text});
      if (createdMessage != null) {
        _reload();

        _scrollToEnd();
      }
    } catch (e) {
      print('Failed to send message: $e');
    }
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
          duration: Duration(milliseconds: 1),
          curve: Curves.easeOut,
        );

        //_scrollController.jumpTo(_scrollController.position.maxScrollExtent);

      }
    });
  }

  String _formatFullDate(DateTime date) {
    final DateTime adjustedDate = date;
    return DateFormat('EEEE d MMMM y', 'fr_FR').format(adjustedDate);
  }

  String _formatMessageDate(DateTime messageDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (messageDate.isAtSameMomentAs(today)) {
      return 'Aujourd\'hui';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
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
              return Text('Loading...');
            } else if (snapshot.hasError) {
              return Text('Error');
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
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load chat'));
          } else {
            User contact = snapshot.data!;
            return Column(
              children: <Widget>[
                Flexible(
                  child: ListView.builder(
                    padding: EdgeInsets.all(8.0),
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
                            onCopy: _copyMessage,
                            onSave: _saveMessage,
                            previousMessageDate: _previousMessageDate,
                          ),
                          if (_isLastReadMessageByCurrentUser(index))
                            Padding(
                              padding: const EdgeInsets.only(top: 5.0, right: 10.0),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundImage: NetworkImage(contact.photo ?? ''),
                              ),
                            ),
                        ],
                      );
                    },
                    itemCount: _messages.length,
                  ),
                ),
                if (_previewFile != null)
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      children: [
                        if (_previewType == 'image')
                          Image.file(
                            _previewFile!,
                            height: 100,
                            width: 100,
                          ),
                        if (_previewType == 'audio')
                        AudioMessagePlayer(audioUrl: _previewFile!.path ?? ''),
                        if (_previewType == 'file') Text(_previewFile!.path.split('/').last),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.cancel),
                              onPressed: _cancelPreview,
                            ),
                            IconButton(
                              icon: Icon(Icons.send),
                              onPressed: () => _sendPreview(contact),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Divider(height: 1.0),
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

 Widget _buildTextComposer(User contact) {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).primaryColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.photo),
              onPressed: () => _pickImage(contact),
            ),
            IconButton(
              icon: Icon(Icons.attach_file),
              onPressed: () => _pickFileAndSend(contact),
            ),
            IconButton(
              icon: Icon(_isRecording ? Icons.mic : Icons.mic_none),
              onPressed: _isRecording ? _stopRecording : () => _startRecording(),
            ),
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: (text) => _handleSubmitted(text),
                decoration: InputDecoration.collapsed(hintText: 'Envoyer un message'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }


  bool _shouldShowDate(DateTime messageDate) {
    if (_previousMessageDate == null) return true;

    final currentDate = DateTime(messageDate.year, messageDate.month, messageDate.day);
    final previousDate = DateTime(_previousMessageDate!.year, _previousMessageDate!.month, _previousMessageDate!.day);

    return currentDate != previousDate;
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  Future<void> _startRecording() async {
    final bool hasPermission = await _requestRecorderPermissions();
    if (!hasPermission) {
      print('Permissions not granted');
      return;
    }

    Directory tempDir = await getTemporaryDirectory();
    String filePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder!.startRecorder(
      toFile: filePath,
      codec: Codec.aacADTS,
    );

    setState(() {
      _isRecording = true;
      _audioPath = filePath;
    });
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
      });

      if (_audioPath != null) {
        setState(() {
          _previewFile = File(_audioPath!);
          _previewType = 'audio';
        });
      }
    }
  }

  Future<Duration> _getAudioDuration(File audioFile) async {
    FlutterSoundHelper helper = FlutterSoundHelper();
  
    return Duration.zero;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  void _cancelPreview() {
    setState(() {
      _previewFile = null;
      _previewType = null;
    });
  }

  Future<void> _sendPreview(User contact) async {
    if (_previewFile == null) return;

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
  }

  void _deleteMessage(String messageId) async {
    await _messageService.deleteMessage(messageId).catchError((e) {
      print('Failed to delete message: $e');
    }).whenComplete(() {
      _reload();
    });
  }

  void _transferMessage(String messageId) async {
    print('messaage : $messageId');
    final selectedContact = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(builder: (context) => ContactScreen()),
    );

    if (selectedContact != null) {
      try {
        print('id:${selectedContact.id} nom:${selectedContact.nom} nom:${selectedContact.type}');
        await _messageService.transferMessage(selectedContact.id, messageId);
        print('Message transferred successfully');
        _reload();
      } catch (e) {
        print('Failed to transfer message: $e');
      }
    }
  }

  void _saveMessage() {
    DirectMessage? lastMessage = _messages.isNotEmpty ? _messages.first : null;
    if (lastMessage != null) {
      setState(() {
/*         _messagesSaved.add(lastMessage); */
      });
    }
  }

  void _copyMessage() {
    DirectMessage? lastMessage = _messages.isNotEmpty ? _messages.first : null;
    if (lastMessage != null) {
      Clipboard.setData(ClipboardData(text: lastMessage.contenu.texte ?? ''));
    }
  }
}

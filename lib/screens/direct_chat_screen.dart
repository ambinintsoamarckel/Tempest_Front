import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Added for Clipboard
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Added for secure storage
import '../models/direct_message.dart';
import '../widgets/direct_message_widget.dart';
import '../utils/discu_file_picker.dart';
import '../services/discu_message_service.dart';

class DirectChatScreen extends StatefulWidget {
  final String id;

  DirectChatScreen({required this.id});
  @override
  _DirectChatScreenState createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final List<DirectMessage> _messages = [];
  final List<DirectMessage> _messagesTransferred = [];
  final List<DirectMessage> _messagesSaved = [];
  final TextEditingController _textController = TextEditingController();
  final MessageService _messageService = MessageService();
  late Future<User> _contactFuture;

  @override
  void initState() {
    super.initState();
    _contactFuture = _loadContact(); // Load contact during initialization
  }

  Future<User> _loadContact() async {
    try {
      List<DirectMessage> messages = await _messageService.receiveMessagesFromUrl(widget.id);
      setState(() {
        _messages.addAll(messages);
      });
      return messages[0].expediteur.id == widget.id ? messages[0].expediteur : messages[0].destinataire;
    } catch (e) {
      print('Failed to load messages: $e');
      rethrow;
    }
  }

  // Request permissions
  Future<bool> _requestPermissions() async {
    final List<Permission> permissions = [Permission.camera, Permission.storage];
    Map<Permission, PermissionStatus> permissionStatus = await permissions.request();

    return permissionStatus[Permission.camera] == PermissionStatus.granted &&
        permissionStatus[Permission.storage] == PermissionStatus.granted;
  }

  // Pick image from gallery
  Future<void> _pickImage(User contact) async {
    final bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      print('Permissions not granted');
      return;
    }

    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      _sendImage(pickedImage.path, contact);
    }
  }

  // Take photo with camera
  Future<void> _takePhoto(User contact) async {
    final bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      print('Permissions not granted');
      return;
    }

    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      _sendImage(pickedImage.path, contact);
    }
  }

  // Send image message
  void _sendImage(String imagePath, User contact) async {
    DirectMessage message = DirectMessage(
      id: '',
      contenu: MessageContent(type: MessageType.image, image: imagePath),
      expediteur: contact,
      destinataire: User(id: widget.id, nom: 'Other User', email: ''),
      dateEnvoi: DateTime.now(),
      lu: false,
    );

    try {
      DirectMessage? createdMessage = await _messageService.createMessage(widget.id, message.toJson());
      if (createdMessage != null) {
        setState(() {
          _messages.insert(0, createdMessage);
        });
      }
    } catch (e) {
      print('Failed to send image: $e');
    }
  }

  // Handle submitted text message
  void _handleSubmitted(String text, User contact) async {
    _textController.clear();
    DirectMessage message = DirectMessage(
      id: '',
      contenu: MessageContent(type: MessageType.texte, texte: text),
      expediteur: contact,
      destinataire: User(id: widget.id, nom: 'Other User', email: ''),
      dateEnvoi: DateTime.now(),
      lu: false,
    );

    try {
      DirectMessage? createdMessage = await _messageService.createMessage(widget.id, message.toJson());
      if (createdMessage != null) {
        setState(() {
          _messages.insert(0, createdMessage);
        });
      }
    } catch (e) {
      print('Failed to send message: $e');
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
                    reverse: true,
                    itemBuilder: (_, int index) => DirectMessageWidget(
                      message: _messages[index],
                      contact: contact, // Pass contact to widget
                      onDelete: _deleteMessage,
                      onTransfer: _transferMessage,
                      onCopy: _copyMessage,
                      onSave: _saveMessage,
                    ),
                    itemCount: _messages.length,
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
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.photo_camera),
              onPressed: () => _takePhoto(contact),
            ),
            IconButton(
              icon: Icon(Icons.photo),
              onPressed: () => _pickImage(contact),
            ),
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: (text) => _handleSubmitted(text, contact),
                decoration: InputDecoration.collapsed(
                  hintText: "Send a message",
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text, contact),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMessage(String messageId) {
    setState(() {
      _messages.removeWhere((message) => message.id == messageId);
    });

    _messageService.deleteMessage(messageId).catchError((e) {
      print('Failed to delete message: $e');
    });
  }

  void _transferMessage(String messageId) {
    DirectMessage messageToTransfer = _messages.firstWhere(
      (message) => message.id == messageId,
      orElse: () => DirectMessage(
        id: '',
        contenu: MessageContent(type: MessageType.texte, texte: ''),
        expediteur: User(id: '', nom: '', email: ''),
        destinataire: User(id: '', nom: '', email: ''),
        dateEnvoi: DateTime.now(),
        lu: false,
      ),
    );
    setState(() {
      _messages.removeWhere((message) => message.id == messageId);
      _messagesTransferred.add(messageToTransfer);
    });
  }

  void _saveMessage() {
    DirectMessage? lastMessage = _messages.isNotEmpty ? _messages.first : null;
    if (lastMessage != null) {
      setState(() {
        _messagesSaved.add(lastMessage);
      });
    }
  }

  void _copyMessage() {
    DirectMessage? lastMessage = _messages.isNotEmpty ? _messages.first : null;
    if (lastMessage != null) {
      Clipboard.setData(ClipboardData(text: lastMessage.contenu.texte ?? ''));
    }
  }

  // Pick file from local storage
  Future<void> _pickFile(User contact) async {
    String? filePath = await FilePickerUtil.pickFile();
    if (filePath != null) {
      _sendFile(filePath, contact);
    }
  }

  // Send file message
  void _sendFile(String filePath, User contact) async {
    DirectMessage message = DirectMessage(
      id: '',
      contenu: MessageContent(type: MessageType.fichier, fichier: filePath),
      expediteur: contact,
      destinataire: User(id: widget.id, nom: 'Other User', email: ''),
      dateEnvoi: DateTime.now(),
      lu: false,
    );

    try {
      DirectMessage? createdMessage = await _messageService.createMessage(widget.id, message.toJson());
      if (createdMessage != null) {
        setState(() {
          _messages.insert(0, createdMessage);
        });
      }
    } catch (e) {
      print('Failed to send file: $e');
    }
  }

  // Handle sending an audio message (stub function, implement as needed)
  void _sendAudio(String audioPath, User contact) async {
    // Your implementation to send audio message
  }

  // Pick audio from local storage
  Future<void> _pickAudio(User contact) async {
/*     String? audioPath = await FilePickerUtil.pickAudio();
    if (audioPath != null) {
      _sendAudio(audioPath, contact);
    } */
  }
}

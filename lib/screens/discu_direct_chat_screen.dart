/*import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Added for Clipboard
import '../models/discu_direct_message.dart';
import '../widgets/discu_direct_message_widget.dart';
import '../utils/discu_file_picker.dart';
import '../services/discu_message_service.dart';

class DirectChatScreen extends StatefulWidget {
  @override
  _DirectChatScreenState createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final List<DirectMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final MessageService _messageService = MessageService(baseUrl: 'http://mahm.tempest.dov:3000');
  late String _currentUser; // Variable pour le nom de l'utilisateur actuel
  late String _otherUser; // Variable pour le nom de l'autre utilisateur

  @override
  void initState() {
    super.initState();
    // Initialisation des noms d'utilisateurs (à ajuster selon votre logique)
    _currentUser = "User A";
    _otherUser = "User B";
  }

  // Méthode pour vérifier et demander les permissions de la caméra et du stockage
  Future<bool> _requestPermissions() async {
    final List<Permission> permissions = [
      Permission.camera,
      Permission.storage,
    ];

    Map<Permission, PermissionStatus> permissionStatus = await permissions.request();

    return permissionStatus[Permission.camera] == PermissionStatus.granted &&
        permissionStatus[Permission.storage] == PermissionStatus.granted;
  }

  // Méthode pour choisir une image depuis la galerie
  Future<void> _pickImage() async {
    final bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      print('Permissions non accordées');
      return;
    }

    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      _sendImage(pickedImage.path);
    }
  }

  // Méthode pour prendre une photo à partir de l'appareil photo
  Future<void> _takePhoto() async {
    final bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      print('Permissions non accordées');
      return;
    }

    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      _sendImage(pickedImage.path);
    }
  }

  // Méthode pour envoyer une image
  void _sendImage(String imagePath) async {
    DirectMessage message = DirectMessage(
      id: '',
      content: imagePath,
      sender: _currentUser,
      timestamp: DateTime.now(),
      type: MessageType.image,
    );

    try {
      DirectMessage? createdMessage = await _messageService.createMessage(message.toJson());
      if (createdMessage != null) {
        setState(() {
          _messages.insert(0, createdMessage);
        });
      }
    } catch (e) {
      print('Failed to send image: $e');
    }
  }

  // Méthode pour gérer l'envoi de messages texte
  void _handleSubmitted(String text) async {
    _textController.clear();
    DirectMessage message = DirectMessage(
      id: '',
      content: text,
      sender: _currentUser,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    try {
      DirectMessage? createdMessage = await _messageService.createMessage(message.toJson());
      if (createdMessage != null) {
        setState(() {
          _messages.insert(0, createdMessage);
        });
      }
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  // Méthode pour basculer entre les utilisateurs
  void _toggleUser() {
    setState(() {
      String temp = _currentUser;
      _currentUser = _otherUser;
      _otherUser = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Direct Chat ($_currentUser)'),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz),
            onPressed: _toggleUser,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => DirectMessageWidget(
                message: _messages[index],
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
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  // Widget pour composer et envoyer des messages
  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.photo_camera),
              onPressed: _takePhoto,
            ),
            IconButton(
              icon: Icon(Icons.photo),
              onPressed: _pickImage,
            ),
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(
                  hintText: "Envoyer un message",
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes pour gérer les messages
  void _deleteMessage(String messageId) {
    setState(() {
      _messages.removeWhere((message) => message.id == messageId);
    });

    _messageService.deleteMessage(messageId).catchError((e) {
      print('Failed to delete message: $e');
    });
  }

  void _transferMessage(String messageId) {
    print('Transférer le message: $messageId');
    DirectMessage messageToTransfer = _messages.firstWhere(
      (message) => message.id == messageId,
      orElse: () => DirectMessage(
        id: '',
        content: '',
        sender: '',
        timestamp: DateTime.now(),
        type: MessageType.text,
      ),
    );
    setState(() {
      _messages.removeWhere((message) => message.id == messageId);
      _messagesTransferred.add(messageToTransfer);
    });
    // Additional logic as needed
  }

  void _saveMessage() {
    DirectMessage? lastMessage = _messages.isNotEmpty ? _messages.first : null;
    if (lastMessage != null) {
      setState(() {
        _messagesSaved.add(lastMessage);
      });
      // Additional logic as needed
    }
  }

  void _copyMessage() {
    DirectMessage? lastMessage = _messages.isNotEmpty ? _messages.first : null;
    if (lastMessage != null) {
      Clipboard.setData(ClipboardData(text: lastMessage.content));
      // Additional logic as needed
    }
  }

  // Méthodes pour choisir un fichier à partir du stockage local
  Future<void> _pickFile() async {
    String? filePath = await FilePickerUtil.pickFile();
    if (filePath != null) {
      _sendFile(filePath);
    }
  }

  // Méthode pour envoyer un fichier
  void _sendFile(String filePath) async {
    DirectMessage message = DirectMessage(
      id: '',
      content: filePath,
      sender: _currentUser,
      timestamp: DateTime.now(),
      type: MessageType.file,
    );

    try {
      DirectMessage? createdMessage = await _messageService.createMessage(message.toJson());
      if (createdMessage != null) {
        setState(() {
          _messages.insert(0, createdMessage);
        });
      }
    } catch (e) {
      print('Failed to send file: $e');
    }
  }
}*/


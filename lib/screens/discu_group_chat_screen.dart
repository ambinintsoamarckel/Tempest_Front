import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Added for Clipboard
import '../models/discu_group_message.dart'; // Changed to GroupMessage
import '../widgets/discu_group_message_widget.dart'; // Changed to GroupMessageWidget
import '../utils/discu_file_picker.dart';
import '../services/discu_group_chat_service.dart'; // Changed to GroupChatService

class GroupChatScreen extends StatefulWidget {
  final String groupId; // Add groupId

  GroupChatScreen({required this.groupId}); // Update constructor

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final List<GroupMessage> _messages = []; // Changed to GroupMessage
  final TextEditingController _textController = TextEditingController();
  final GroupChatService _messageService =
  GroupChatService(baseUrl: 'http://mahm.tempest.dov:3000'); // Changed to GroupChatService
  String _currentUser = "User 1";
  List<GroupMessage> _messagesTransferred = []; // Added for transfer
  List<GroupMessage> _messagesSaved = []; // Added for save

  // Méthode pour vérifier et demander les permissions de la caméra et du stockage
  Future<bool> _requestPermissions() async {
    final List<Permission> permissions = [
      Permission.camera,
      Permission.storage,
    ];

    Map<Permission, PermissionStatus> permissionStatus =
    await permissions.request();

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

    final XFile? pickedImage =
    await ImagePicker().pickImage(source: ImageSource.gallery);
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

    final XFile? pickedImage =
    await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      _sendImage(pickedImage.path);
    }
  }

  // Méthode pour envoyer une image
  void _sendImage(String imagePath) async {
    GroupMessage message = GroupMessage(
      id: '',
      content: imagePath,
      sender: _currentUser,
      groupId: widget.groupId, // Added groupId
      timestamp: DateTime.now(),
      type: MessageType.image,
    );

    try {
      GroupMessage? createdMessage =
      await _messageService.createGroupMessage(widget.groupId, message.toJson()); // Changed to createGroupMessage
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
    GroupMessage message = GroupMessage(
      id: '',
      content: text,
      sender: _currentUser,
      groupId: widget.groupId, // Added groupId
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    try {
      GroupMessage? createdMessage =
      await _messageService.createGroupMessage(widget.groupId, message.toJson()); // Changed to createGroupMessage
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
      _currentUser = _currentUser == "User 1" ? "User 2" : "User 1";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Chat'), // Changed title
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
              itemBuilder: (_, int index) => GroupMessageWidget( // Changed to GroupMessageWidget
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
              icon: Icon(Icons.attach_file),
              onPressed: _pickFile,
            ),
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

    _messageService.deleteGroupMessage(widget.groupId, messageId).catchError((e) { // Changed to deleteGroupMessage
      print('Failed to delete message: $e');
    });
  }

  void _transferMessage(String messageId) {
    print('Transférer le message: $messageId');
    GroupMessage messageToTransfer = _messages.firstWhere(
          (message) => message.id == messageId,
      orElse: () => GroupMessage(
        id: '',
        content: '',
        sender: '',
        groupId: widget.groupId,
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
    GroupMessage? lastMessage = _messages.isNotEmpty ? _messages.first : null;
    if (lastMessage != null) {
      setState(() {
        _messagesSaved.add(lastMessage);
      });
      // Additional logic as needed
    }
  }

  void _copyMessage() {
    GroupMessage? lastMessage = _messages.isNotEmpty ? _messages.first : null;
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
    GroupMessage message = GroupMessage(
      id: '',
      content: filePath,
      sender: _currentUser,
      groupId: widget.groupId, // Added groupId
      timestamp: DateTime.now(),
      type: MessageType.file,
    );

    try {
      GroupMessage? createdMessage =
      await _messageService.createGroupMessage(widget.groupId, message.toJson()); // Changed to createGroupMessage
      if (createdMessage != null) {
        setState(() {
          _messages.insert(0, createdMessage);
        });
      }
    } catch (e) {
      print('Failed to send file: $e');
    }
  }
}

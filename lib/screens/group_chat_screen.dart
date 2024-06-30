import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Added for Clipboard
import '../models/group_message.dart';
import '../widgets/group_message_widget.dart';
import '../utils/discu_file_picker.dart';
import '../services/discu_group_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  GroupChatScreen({required this.groupId});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final List<GroupMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final GroupChatService _messageService = GroupChatService(baseUrl: 'http://mahm.tempest.dov:3000');
  String _currentUser = "User 1";
  String _currentRecipient = "User 2"; // Initial recipient
  List<GroupMessage> _messagesTransferred = [];
  List<GroupMessage> _messagesSaved = [];

  // Method to request camera and storage permissions
  Future<bool> _requestPermissions() async {
    final List<Permission> permissions = [
      Permission.camera,
      Permission.storage,
    ];

    Map<Permission, PermissionStatus> permissionStatus = await permissions.request();

    return permissionStatus[Permission.camera] == PermissionStatus.granted &&
        permissionStatus[Permission.storage] == PermissionStatus.granted;
  }

  // Method to pick an image from gallery
  Future<void> _pickImage() async {
    final bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      print('Permissions not granted');
      return;
    }

    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      _sendImage(pickedImage.path);
    }
  }

  // Method to take a photo from camera
  Future<void> _takePhoto() async {
    final bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      print('Permissions not granted');
      return;
    }

    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      _sendImage(pickedImage.path);
    }
  }

  // Method to send an image
  void _sendImage(String imagePath) async {
    GroupMessage message = GroupMessage(
      id: '',
      content: imagePath,
      sender: _currentUser,
      recipient: _currentRecipient,
      groupId: widget.groupId,
      timestamp: DateTime.now(),
      type: MessageType.image,
    );

    try {
      GroupMessage? createdMessage =
      await _messageService.createGroupMessage(widget.groupId, message.toJson());
      if (createdMessage != null) {
        setState(() {
          _messages.insert(0, createdMessage);
        });
      }
    } catch (e) {
      print('Failed to send image: $e');
    }
  }

  // Method to handle submission of text messages
  void _handleSubmitted(String text) async {
    _textController.clear();
    GroupMessage message = GroupMessage(
      id: '',
      content: text,
      sender: _currentUser,
      recipient: _currentRecipient,
      groupId: widget.groupId,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    try {
      GroupMessage? createdMessage =
      await _messageService.createGroupMessage(widget.groupId, message.toJson());
      if (createdMessage != null) {
        setState(() {
          _messages.insert(0, createdMessage);
        });
      }
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  // Method to toggle between users
  void _toggleUser() {
    setState(() {
      String temp = _currentUser;
      _currentUser = _currentRecipient;
      _currentRecipient = temp;
    });
  }

  // Widget to compose and send messages
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
                  hintText: "Send a message",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Chat'),
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
              itemBuilder: (_, int index) => GroupMessageWidget(
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

  // Methods to handle messages
  void _deleteMessage(String messageId) {
    setState(() {
      _messages.removeWhere((message) => message.id == messageId);
    });

    _messageService.deleteGroupMessage(widget.groupId, messageId).catchError((e) {
      print('Failed to delete message: $e');
    });
  }

  void _transferMessage(String messageId) {
    print('Transfer message: $messageId');
    GroupMessage messageToTransfer = _messages.firstWhere(
          (message) => message.id == messageId,
      orElse: () => GroupMessage(
        id: '',
        content: '',
        sender: '',
        recipient: '',
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

  // Methods to pick a file from local storage
  Future<void> _pickFile() async {
    String? filePath = await FilePickerUtil.pickFile();
    if (filePath != null) {
      _sendFile(filePath);
    }
  }

  // Method to send a file
  void _sendFile(String filePath) async {
    GroupMessage message = GroupMessage(
      id: '',
      content: filePath,
      sender: _currentUser,
      recipient: _currentRecipient,
      groupId: widget.groupId,
      timestamp: DateTime.now(),
      type: MessageType.file,
    );

    try {
      GroupMessage? createdMessage =
      await _messageService.createGroupMessage(widget.groupId, message.toJson());
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

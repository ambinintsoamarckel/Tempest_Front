import 'package:flutter/material.dart';
import '../models/direct_message.dart';
import '../widgets/direct_message_widget.dart';
import '../utils/file_picker.dart';
import '../utils/image_picker.dart';

class DirectChatScreen extends StatefulWidget {
  @override
  _DirectChatScreenState createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final List<DirectMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  String _currentUser = "User 1";

  void _handleSubmitted(String text) {
    _textController.clear();
    DirectMessage message = DirectMessage(
      content: text,
      sender: _currentUser,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _sendFile(String filePath) {
    DirectMessage message = DirectMessage(
      content: filePath,
      sender: _currentUser,
      timestamp: DateTime.now(),
      type: MessageType.file,
    );
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _sendImage(String imagePath) {
    DirectMessage message = DirectMessage(
      content: imagePath,
      sender: _currentUser,
      timestamp: DateTime.now(),
      type: MessageType.image,
    );
    setState(() {
      _messages.insert(0, message);
    });
  }

  Future<void> _pickFile() async {
    String? filePath = await FilePickerUtil.pickFile();
    if (filePath != null) {
      _sendFile(filePath);
    }
  }

  Future<void> _pickImage() async {
    String? imagePath = await ImagePickerUtil.pickImage();
    if (imagePath != null) {
      _sendImage(imagePath);
    }
  }

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

  void _toggleUser() {
    setState(() {
      _currentUser = _currentUser == "User 1" ? "User 2" : "User 1";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Direct Chat'),
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
              itemBuilder: (_, int index) => DirectMessageWidget(message: _messages[index]),
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
}

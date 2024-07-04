import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Added for Clipboard
import '../models/group_message.dart';
import '../widgets/group_message_widget.dart';
import '../utils/discu_file_picker.dart';
import '../services/discu_group_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  GroupChatScreen({required this.groupId});
  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final List<GroupMessage> _messages = [];
  final List<GroupMessage> _messagesTransferred = [];
  final List<GroupMessage> _messagesSaved = [];
  final TextEditingController _textController = TextEditingController();
  final GroupChatService _messageService = GroupChatService();
  late Future<Group> _groupFuture;
  final storage = FlutterSecureStorage();
  late Future<String> _currentUser;

  @override
  void initState() {
    super.initState();
    _groupFuture = _loadGroup();
    _currentUser = _loadCurrentUser();
  }

  Future<String> _loadCurrentUser() async {
    String? user = await storage.read(key: 'user');
    user = user!.replaceAll('"', '').trim();
    return user;
  }

  Future<Group> _loadGroup() async {
    try {
      List<GroupMessage> messages = await _messageService.receiveGroupMessages(widget.groupId);
      setState(() {
        _messages.addAll(messages);
      });
      return messages[0].groupe;
    } catch (e) {
      print('Failed to load messages: $e');
      rethrow;
    }
  }

  Future _reload() async {
    try {
      List<GroupMessage> messages = await _messageService.receiveGroupMessages(widget.groupId);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
    } catch (e) {
      print('Failed to load messages: $e');
      rethrow;
    }
  }

  Future<bool> _requestPermissions() async {
    final List<Permission> permissions = [Permission.camera, Permission.storage];
    Map<Permission, PermissionStatus> permissionStatus = await permissions.request();
    return permissionStatus[Permission.camera] == PermissionStatus.granted &&
        permissionStatus[Permission.storage] == PermissionStatus.granted;
  }

  Future<void> _pickImage() async {
    final bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      print('Permissions not granted');
      return;
    }

    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      _sendFile(pickedImage.path);
    }
  }

  Future<void> _pickFileAndSend() async {
    try {
      String? filePath = await FilePickerUtil.pickFile();
      if (filePath != null) {
        _sendFile(filePath);
      }
    } catch (e) {
      print('Failed to pick and send file: $e');
    }
  }

  Future<void> _takePhoto() async {
    final bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      print('Permissions not granted');
      return;
    }

    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      _sendFile(pickedImage.path);
    }
  }

  void _handleSubmitted(String text) async {
    _textController.clear();
    try {
      bool? createdMessage = await _messageService.createMessage(widget.groupId, {"texte": text});
      if (createdMessage != null) {
        _reload();
      }
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  bool _isLastReadMessageByCurrentUser(int index) {
    if (_messages.isEmpty || index != _messages.length - 1) return false;
    GroupMessage message = _messages[index];
    return message.luPar!.contains(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Group>(
          future: _groupFuture,
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
      body: FutureBuilder<Group>(
        future: _groupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load chat'));
          } else {
            return Column(
              children: <Widget>[
                Flexible(
                  child: FutureBuilder<String>(
                    future: _currentUser,
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (userSnapshot.hasError) {
                        return Center(child: Text('Failed to load user'));
                      } else {
                        return ListView.builder(
                          padding: EdgeInsets.all(8.0),
                          reverse: false,
                          itemBuilder: (_, int index) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                GroupMessageWidget(
                                  message: _messages[index],
                                  currentUser: userSnapshot.data!,
                                  onDelete: _deleteMessage,
                                  onTransfer: _transferMessage,
                                  onCopy: _copyMessage,
                                  onSave: _saveMessage,
                                ),
                                if (_isLastReadMessageByCurrentUser(index))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5.0, right: 10.0),
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundImage: NetworkImage(snapshot.data!.membres.firstWhere((member) => member.id == widget.groupId).photo ?? ''),
                                    ),
                                  ),
                              ],
                            );
                          },
                          itemCount: _messages.length,
                        );
                      }
                    },
                  ),
                ),
                Divider(height: 1.0),
                Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: _buildTextComposer(snapshot.data!),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildTextComposer(Group group) {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.photo_camera),
              onPressed: () => _takePhoto(),
            ),
            IconButton(
              icon: Icon(Icons.photo),
              onPressed: () => _pickImage(),
            ),
            IconButton(
              icon: Icon(Icons.attach_file),
              onPressed: () => _pickFileAndSend(),
            ),
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: (text) => _handleSubmitted(text),
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

  void _deleteMessage(String messageId) async {
    try {
      await _messageService.deleteMessage(widget.groupId, messageId);
      _reload(); // Recharge les messages après la suppression réussie
    } catch (e) {
      print('Failed to delete message: $e');
      // Gérer l'erreur selon les besoins
    }
  }


  void _transferMessage(String messageId) {
    // Implementation for transferring a message
  }

  void _saveMessage() {
    GroupMessage? lastMessage = _messages.isNotEmpty ? _messages.first : null;
    if (lastMessage != null) {
      setState(() {
        _messagesSaved.add(lastMessage);
      });
    }
  }

  void _copyMessage() {
    GroupMessage? lastMessage = _messages.isNotEmpty ? _messages.first : null;
    if (lastMessage != null) {
      Clipboard.setData(ClipboardData(text: lastMessage.contenu.texte ?? ''));
    }
  }

  void _sendFile(String filePath) async {
    try {
      bool success = await _messageService.sendFileToGroup(widget.groupId, filePath);
      if (success) {
        print('File sent successfully');
        _reload();
      } else {
        print('Failed to send file');
      }
    } catch (e) {
      print('Exception during file sending: $e');
    }
  }

  Future<void> _pickAudio() async {
    // Implementation for picking audio
  }
}

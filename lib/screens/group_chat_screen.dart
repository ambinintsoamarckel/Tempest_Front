import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Added for Clipboard
import '../models/group_message.dart';
import '../widgets/group_message_widget.dart';
import '../utils/discu_file_picker.dart';
import '../services/discu_group_service.dart';
import 'contacts_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/contact.dart';
import 'package:dio/dio.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  GroupChatScreen({required this.groupId});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final List<GroupMessage> _messages = [];
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
                                  onDelete: (messageId) => _deleteMessage(messageId, widget.groupId),
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

  void _deleteMessage(String messageId, String groupId) async {
    try {
      await _messageService.deleteMessage(messageId, groupId);
      print('Message deleted successfully');
      _reload(); // Recharge les messages après la suppression réussie
    } on DioError catch (e) {
      if (e.response != null && e.response!.statusCode == 404) {
        print('Message not found or already deleted');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le message est introuvable ou a déjà été supprimé.')),
        );
      } else if (e.response != null) {
        print('Failed to delete message: ${e.response!.statusCode} - ${e.response!.statusMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de suppression: ${e.response!.statusCode} ${e.response!.statusMessage}')),
        );
      } else {
        print('Unexpected error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur inattendue, veuillez réessayer.')),
        );
      }
    } catch (e) {
      print('Failed to delete message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inattendue, veuillez réessayer.')),
      );
    }
  }

  void _transferMessage(String messageId) async {
    final selectedContact = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(builder: (context) => const ContactScreen()),
    );

    if (selectedContact != null) {
      try {
        await _messageService.transferMessage(selectedContact.id, messageId);
        print('Message transferred successfully');
        _reload();
      } on DioError catch (e) {
        if (e.response != null) {
          print('Erreur de réponse du serveur ${e.response!.statusCode}: ${e.response!.statusMessage}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur du serveur: ${e.response!.statusCode} ${e.response!.statusMessage}')),
          );
        } else {
          print('Erreur inattendue: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur inattendue, veuillez réessayer.')),
          );
        }
      } catch (e) {
        print('Failed to transfer message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur inattendue, veuillez réessayer.')),
        );
      }
    }
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

 /* Future<void> _addMember(String utilisateurId) async {
    try {
      bool success = await _messageService.addMemberToGroup(widget.groupId, utilisateurId);
      if (success) {
        print('Member added successfully');
        _reload(); // Recharge les informations du groupe après l'ajout réussi
      } else {
        print('Failed to add member');
      }
    } catch (e) {
      print('Failed to add member: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout du membre, veuillez réessayer.')),
      );
    }
  }

  Future<void> _removeMember(String utilisateurId) async {
    try {
      bool success = await _messageService.removeMemberFromGroup(widget.groupId, utilisateurId);
      if (success) {
        print('Member removed successfully');
        _reload(); // Recharge les informations du groupe après la suppression réussie
      } else {
        print('Failed to remove member');
      }
    } catch (e) {
      print('Failed to remove member: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression du membre, veuillez réessayer.')),
      );
    }
  }
*/

  Future<void> _pickAudio() async {
    // Implementation for picking audio
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}


import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_social_network/models/contact.dart';
import 'package:mini_social_network/screens/contacts_screen.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Added for Clipboard
import '../models/direct_message.dart';
import '../widgets/direct_message_widget.dart';
import '../utils/discu_file_picker.dart';
import '../services/discu_message_service.dart';


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
    final List<DirectMessage> _messagesSaved = [];
  final TextEditingController _textController = TextEditingController();
  final MessageService _messageService = MessageService();
  late Future<User> _contactFuture;
  final CurrentScreenManager screenManager=CurrentScreenManager();

  Future<void> _reload() async {
    try {
      List<DirectMessage> messages = await _messageService.receiveMessagesFromUrl(widget.id);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
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
    screenManager.updateCurrentScreen('directChat'); // Load contact during initialization
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
      _sendFile(pickedImage.path);
    }
  }

  // Fonction pour choisir et envoyer un fichier
  Future<void> _pickFileAndSend(User contact) async {
    try {
      String? filePath = await FilePickerUtil.pickFile();
      if (filePath != null) {
        _sendFile(filePath);
      }
    } catch (e) {
      print('Failed to pick and send file: $e');
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
      _sendFile(pickedImage.path);
    }
  }

  // Handle submitted text message
  void _handleSubmitted(String text) async {
    _textController.clear();

    try {
      bool? createdMessage = await _messageService.createMessage(widget.id, {"texte":text});
      if (createdMessage != null) {
        _reload();
      }
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  bool _isLastReadMessageByCurrentUser(int index) {
    if (_messages.isEmpty || index != _messages.length-1) return false;
    DirectMessage message = _messages[index];
    return message.destinataire.id == widget.id && message.lu;
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
                    reverse: false,
                    itemBuilder: (_, int index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          DirectMessageWidget(
                            message: _messages[index],
                            contact: contact,
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
                                backgroundImage: NetworkImage(contact.photo ?? ''),
                              ),
                            ),
                        ],
                      );
                    },
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
            IconButton(
              icon: Icon(Icons.attach_file),
              onPressed: () => _pickFileAndSend(contact),
            ),
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: (text) => _handleSubmitted(text),
                decoration: InputDecoration.collapsed(
                  hintText: "Send a message",
                ),
                maxLines: null, // Permet au texte de se redimensionner automatiquement
                minLines: 1, // Nombre minimum de lignes affichées
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
    await _messageService.deleteMessage(messageId).catchError((e) {
      print('Failed to delete message: $e');
    }).whenComplete(() {
      _reload();
    });
  }
  void _transferMessage(String messageId) async {
    final selectedContact = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(builder: (context) =>  ContactScreen()),
    );

    if (selectedContact != null) {
      try {
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

  void _sendFile(String filePath) async {
    try {
      bool success = await _messageService.sendFileToPerson(widget.id, filePath);
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

  // Pick audio from local storage
  Future<void> _pickAudio(User contact) async {
    // Implementation for picking audio
  }
}
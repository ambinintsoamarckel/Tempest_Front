import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
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
import 'ctt_screen.dart';
import '../models/contact.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/audio_message_player.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'group_settings.dart';
import '../widgets/RecordingWidget.dart';
import '../main.dart';
class GroupChatScreen extends StatefulWidget {
  final String groupId;
  static final GlobalKey<_GroupChatScreenState> groupChatScreenKey = GlobalKey<_GroupChatScreenState>();

  GroupChatScreen({required this.groupId}) : super(key: groupChatScreenKey);

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();

  void reload() {
    final state = groupChatScreenKey.currentState;
    if (state != null) {
      state._reload();
    }
  }
}

class _GroupChatScreenState extends State<GroupChatScreen> with RouteAware{
  final List<GroupMessage> _messages = [];
  final List<GroupMessage> _messagesSaved = [];
  final TextEditingController _textController = TextEditingController();
  final GroupChatService _messageService = GroupChatService();
  late Future<Group> _groupFuture;
  final storage = FlutterSecureStorage();
  late Future<String> _currentUser;
  final CurrentScreenManager screenManager = CurrentScreenManager();
  DateTime? _previousMessageDate;
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _audioPath;
  final ScrollController _scrollController = ScrollController();
  File? _previewFile;
  String? _previewType; // 'image', 'audio', or 'file'

  @override
  void initState() {
    super.initState();
  
    _currentUser = _loadCurrentUser();
      _groupFuture = _loadGroup();
    
    screenManager.updateCurrentScreen('groupChat');
        _initRecorder();
        

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
           WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToEnd();
      });
      return messages[0].groupe;
    } catch (e) {
      print('Failed to load messages: $e');
      rethrow;
    }
  }

  Future<void> _reload() async {
    try {
      List<GroupMessage> messages = await _messageService.receiveGroupMessages(widget.groupId);
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

  Future<void> _pickImage() async {
    print('lancement');
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

  Future<void> _pickFileAndSend() async {
    try {
        print('lancement');
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

  Future<void> _takePhoto() async {
      print('lancement');
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
@override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }
    @override
  void didPopNext() {
    super.didPopNext();
    setState(() {
      _messages.clear();
      _groupFuture = _loadGroup();
      
    });
      
  }
 void _handleSubmitted(String text) async {
    if (text.isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus(); // Fermer le clavier virtuel

    try {
      bool? createdMessage = await _messageService.createMessage(widget.groupId, {"texte": text});
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
         actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () async {
            Group group = await _groupFuture;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupSettingsScreen(groupe: group), // Pass group object
              ),
            );
          },
        ),
      ],
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
                    controller: _scrollController,
                    itemBuilder: (_, int index) {
                      GroupMessage message = _messages[index];
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
                          GroupMessageWidget(
                            message: _messages[index],
                            currentUser: userSnapshot.data!,
                            onDelete: (messageId) => _deleteMessage(messageId, widget.groupId),
                            onTransfer: _transferMessage,
                            onCopy: () => _copyMessage(index),
                          ),
                          if (_isLastReadMessageByCurrentUser(index))
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                "Lu",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
              
            if (_previewFile != null)
                  Container(
                    margin: EdgeInsets.all(10.0),
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 5.0,
                          spreadRadius: 2.0,
                          offset: Offset(0, 2),
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
                          SizedBox(width: 10), // Augmentation de la distance entre le fichier et le nom du fichier
                        ] else if (_previewType == 'audio') ...[
                          Icon(Icons.audiotrack, size: 100, color: Colors.blue),
                          SizedBox(width: 20), // Augmentation de la distance entre le fichier et le nom du fichier
                        ] else if (_previewType == 'file') ...[
                          Icon(Icons.insert_drive_file, size: 95, color: Colors.green),
                          SizedBox(width: 10), // Augmentation de la distance entre le fichier et le nom du fichier
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _previewFile!.path.split('/').last,
                          
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 5),
                              Center(
                                child: Row (
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: _clearPreview,
                                      child: Icon(Icons.delete, size: 40, color: Colors.redAccent), // Icône pour annuler avec taille augmentée
                                    ),
                                    SizedBox(width: 30), // Augmentation de la distance entre les icônes
                                    GestureDetector(
                                      onTap: () => _sendPreview(),
                                      child: Icon(Icons.upload, size: 40, color: Colors.greenAccent), // Icône pour envoyer
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
                  RecordingWidget(),
          
                Divider(height: 1.0),
                Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: _buildTextComposer(),
                   ),
              ],
            );
          }
        },
      ),
    );
  }

 
  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.photo),
              onPressed: () => _pickImage(),
            ),
            IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: () => _takePhoto(),
            ),
            IconButton(
              icon: Icon(Icons.insert_drive_file),
              onPressed: () => _pickFileAndSend(),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(hintText: 'Envoyer un message'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
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

Future<void> _sendPreview() async {
  if (_previewFile == null) return;

  _showProgressDialog();

  try {
    if (_previewType == 'image') {
      await _messageService.sendFileToGroup(widget.groupId, _previewFile!.path);
    } else if (_previewType == 'audio') {
      await _messageService.sendFileToGroup(widget.groupId, _previewFile!.path);
    } else if (_previewType == 'file') {
      await _messageService.sendFileToGroup(widget.groupId, _previewFile!.path);
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
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
  @override
  void dispose() {
    _recorder!.closeRecorder();
    super.dispose();
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
          SnackBar(
            content: Text('Message not found or already deleted'),
          ),
        );
      } else {
        print('Error deleting message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message'),
          ),
        );
      }
    }
  }

 
  void _transferMessage(String messageId) async {
      print('messaage : $messageId');
       Navigator.push<Contact>(
        context,
        MaterialPageRoute(builder: (context) => ContaScreen(isTransferMode: true,id: messageId)),
      );

          _reload();

    }


void _copyMessage(int index) {
  final text = _messages[index].contenu.texte;
  if (text != null) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message copié dans le presse-papiers')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Aucun texte à copier')),
    );
  }

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





}


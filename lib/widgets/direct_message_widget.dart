import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../models/direct_message.dart';
import '../utils/audio_message_player.dart';
import '../utils/video_message_player.dart';
import '../utils/downloader.dart';

class DirectMessageScreen extends StatefulWidget {
  final List<DirectMessage> messages;
  final User contact;
  final String currentUser;
  final Function(String) onDelete;
  final Function(String) onTransfer;
  final VoidCallback? onSave;

  DirectMessageScreen({
    required this.messages,
    required this.contact,
    required this.currentUser,
    required this.onDelete,
    required this.onTransfer,
    this.onSave,
  });

  @override
  _DirectMessageScreenState createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact.nom ?? 'Chat'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: widget.messages.length,
        itemBuilder: (context, index) {
          return DirectMessageWidget(
            message: widget.messages[index],
            contact: widget.contact,
            onDelete: widget.onDelete,
            onTransfer: widget.onTransfer,
            onSave: widget.onSave,
          );
        },
      ),
    );
  }
}

class DirectMessageWidget extends StatelessWidget {
  final DirectMessage message;
  final User contact;
  final VoidCallback? onCopy;
  final Function(String) onDelete;
  final Function(String) onTransfer;
  final VoidCallback? onSave;

  DirectMessageWidget({
    required this.message,
    required this.contact,
    this.onCopy,
    required this.onDelete,
    required this.onTransfer,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final bool isContact = message.expediteur.id == contact.id;
    Widget messageContent;

    switch (message.contenu.type) {
      case MessageType.texte:
        messageContent = _buildTextMessage(context, isContact);
        break;
      case MessageType.fichier:
        messageContent = _buildFileMessage(context, isContact);
        break;
      case MessageType.image:
        messageContent = ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Image.network(
            message.contenu.image ?? '',
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          ),
        );
        break;
      case MessageType.audio:
        messageContent = _buildAudioMessage(context, isContact);
        break;
      case MessageType.video:
        messageContent = _buildVideoMessage(context, isContact);
        break;
      default:
        messageContent = Text('Unsupported message type');
    }

    return GestureDetector(
      onLongPress: () {
        final RenderBox overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;
        showMenu(
          context: context,
          position: RelativeRect.fromRect(
            Rect.fromPoints(
              Offset.zero,
              Offset(overlay.size.width, overlay.size.height),
            ),
            Offset.zero & overlay.size,
          ),
          items: <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'copy',
              child: ListTile(
                leading: Icon(Icons.content_copy),
                title: Text('Copier'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Supprimer'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'transfer',
              child: ListTile(
                leading: Icon(Icons.forward),
                title: Text('Transférer'),
              ),
            ),
            if (message.contenu.type == MessageType.image ||
                message.contenu.type == MessageType.fichier ||
                message.contenu.type == MessageType.audio ||
                message.contenu.type == MessageType.video)
              PopupMenuItem<String>(
                value: 'save',
                child: ListTile(
                  leading: Icon(Icons.save),
                  title: Text('Enregistrer'),
                ),
              ),
          ],
          elevation: 0.0,
        ).then((value) {
          if (value == 'copy' && onCopy != null) {
            onCopy!();
          } else if (value == 'delete') {
            onDelete(message.id);
          } else if (value == 'transfer') {
            onTransfer(message.id);
          } else if (value == 'save' && onSave != null) {
            _saveFile(context);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          mainAxisAlignment: isContact ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
           children: <Widget>[
            if (isContact)...[
              CircleAvatar(
                backgroundImage: contact.photo != null ? NetworkImage(contact.photo!) : null,
              ),
              SizedBox(width: 5),
            ],
 // Limite la largeur à 50% de l'écran
          

            Flexible(
              
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                decoration: BoxDecoration(
                  color:  Colors.grey[300] ,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0),
                    bottomLeft: isContact ? Radius.circular(10.0) : Radius.circular(0.0),
                  ),
                ),
        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    messageContent,
                    SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDate(message.dateEnvoi),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (!isContact)_buildReadStatus(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isContact)
              SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context, bool isContact) {
    return Text(
      message.contenu.texte ?? '',
      style: TextStyle(
        color: Colors.black,
      ),
      softWrap: true,
      overflow: TextOverflow.clip,
    );
  }

  Widget _buildFileMessage(BuildContext context, bool isContact) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.attach_file),
        SizedBox(width: 5),
        Text(
          message.contenu.fichier?.split('/').last ?? '',
          style: TextStyle(
            color:  Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildImageMessage(BuildContext context, bool isContact) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Image.network(
        message.contenu.image ?? '',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildAudioMessage(BuildContext context, bool isContact) {
    return AudioMessagePlayer(audioUrl: message.contenu.audio ?? '');
  }

  Widget _buildVideoMessage(BuildContext context, bool isContact) {
    return VideoMessagePlayer(videoUrl: message.contenu.video ?? '');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return DateFormat.Hm().format(date); // Heure si aujourd'hui
    } else if (difference.inDays == 1) {
      return 'Hier'; // Hier
    } else {
      return DateFormat('yyyy/MM/dd').format(date); // Date en format yyyy/MM/dd
    }
  }

  Widget _buildReadStatus() {
    return message.lu ? Icon(Icons.done_all, color: Colors.blue) : Icon(Icons.done, color: Colors.grey);
  }

  Future<void> _saveFile(BuildContext context) async {
    String type;
    switch (message.contenu.type) {
      case MessageType.image:
        type = "image";
        break;
      case MessageType.audio:
        type = "audio";
        break;
      case MessageType.video:
        type = "video";
        break;
      case MessageType.fichier:
        type = "file";
        break;
      default:
        return;
    }

    final fileUrl = _getFileUrl();
    downloadFile(context, fileUrl, type);
  }

  String _getFileUrl() {
    switch (message.contenu.type) {
      case MessageType.image:
        return message.contenu.image ?? '';
      case MessageType.audio:
        return message.contenu.audio ?? '';
      case MessageType.video:
        return message.contenu.video ?? '';
      case MessageType.fichier:
        return message.contenu.fichier ?? '';
      default:
        return '';
    }
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: BoxDecoration(
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

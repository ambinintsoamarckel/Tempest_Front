import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:photo_view/photo_view.dart';
import '../models/group_message.dart';
import '../utils/audio_message_player.dart';
import '../utils/video_message_player.dart';
import '../utils/downloader.dart';

class GroupMessageWidget extends StatefulWidget {
  final GroupMessage message;
  final String currentUser;
  final VoidCallback? onCopy;
  final Function(String) onDelete;
  final Function(String) onTransfer;
  final VoidCallback? onSave;

  GroupMessageWidget({
    required this.message,
    required this.currentUser,
    this.onCopy,
    required this.onDelete,
    required this.onTransfer,
    this.onSave,
  });

  @override
  _GroupMessageWidgetState createState() => _GroupMessageWidgetState();
}

class _GroupMessageWidgetState extends State<GroupMessageWidget> {
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = widget.message.expediteur.id != widget.currentUser;
    Widget messageContent;

    switch (widget.message.contenu.type) {
      case MessageType.texte:
        messageContent = _buildTextMessage(context, isCurrentUser);
        break;
      case MessageType.fichier:
        messageContent = _buildFileMessage(context, isCurrentUser);
        break;
      case MessageType.image:
        messageContent = _buildImageMessage(context, isCurrentUser);
        break;
      case MessageType.audio:
        messageContent = _buildAudioMessage(context, isCurrentUser);
        break;
      case MessageType.video:
        messageContent = _buildVideoMessage(context, isCurrentUser);
        break;
      default:
        messageContent = Text('Unsupported message type');
    }

    return GestureDetector(
      onLongPress: () {
        _showMessageOptions(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          mainAxisAlignment: !isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (isCurrentUser) ...[
              CircleAvatar(
                backgroundImage: widget.message.expediteur.photo != null ? NetworkImage(widget.message.expediteur.photo!) : null,
              ),
              SizedBox(width: 5),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Column(
                  crossAxisAlignment: !isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (isCurrentUser)
                      Text(
                        widget.message.expediteur.nom ?? 'Anonyme',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Container(
                      margin: EdgeInsets.only(top: 5.0),
                      padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                      decoration: BoxDecoration(
                        color: isCurrentUser ? Colors.grey[300] : Colors.blue[100],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10.0),
                          topRight: Radius.circular(10.0),
                          bottomRight: Radius.circular(10.0),
                          bottomLeft: isCurrentUser ? Radius.circular(10.0) : Radius.circular(0.0),
                        ),
                      ),
                      child: messageContent,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDate(widget.message.dateEnvoi),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (!isCurrentUser) _buildReadStatus(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isCurrentUser) SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context, bool isCurrentUser) {
    return Text(
      widget.message.contenu.texte ?? '',
      style: TextStyle(
        color: Colors.black,
      ),
      softWrap: true,
      overflow: TextOverflow.clip,
    );
  }

  Widget _buildFileMessage(BuildContext context, bool isCurrentUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.attach_file),
        SizedBox(width: 5),
        Text(
          widget.message.contenu.fichier?.split('/').last ?? '',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildImageMessage(BuildContext context, bool isCurrentUser) {
    return GestureDetector(
      onTap: () => _openFullScreenImage(context, widget.message.contenu.image ?? ''),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Image.network(
          widget.message.contenu.image ?? '',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildAudioMessage(BuildContext context, bool isCurrentUser) {
    return AudioMessagePlayer(audioUrl: widget.message.contenu.audio ?? '');
  }

  Widget _buildVideoMessage(BuildContext context, bool isCurrentUser) {
    return VideoMessagePlayer(videoUrl: widget.message.contenu.video ?? '');
  }

  String _formatDate(DateTime date) {
    final DateTime adjustedDate = date.add(Duration(hours: 3)); // Ajouter 3 heures pour GMT+3
    return DateFormat.Hm().format(adjustedDate); // Heure si aujourd'hui
  }

  Widget _buildReadStatus() {
    return widget.message.luPar!.isNotEmpty ? Icon(Icons.done_all, color: Colors.blue) : Icon(Icons.done, color: Colors.grey);
  }

  Future<void> _saveFile(BuildContext context) async {
    String type;
    switch (widget.message.contenu.type) {
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
    print('$fileUrl $type');
    await downloadFile(_scaffoldMessenger!, fileUrl, type);
  }

  String _getFileUrl() {
    switch (widget.message.contenu.type) {
      case MessageType.image:
        return widget.message.contenu.image ?? '';
      case MessageType.audio:
        return widget.message.contenu.audio ?? '';
      case MessageType.video:
        return widget.message.contenu.video ?? '';
      case MessageType.fichier:
        return widget.message.contenu.fichier ?? '';
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

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.message.contenu.type == MessageType.texte)
                ListTile(
                  leading: Icon(Icons.copy, color: Colors.blueAccent),
                  title: Text('Copier'),
                  onTap: () {
                    widget.onCopy?.call();
                    Navigator.of(context).pop();
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.redAccent),
                title: Text('Supprimer'),
                onTap: () {
                  widget.onDelete(widget.message.id);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.forward, color: Colors.greenAccent),
                title: Text('Transférer'),
                onTap: () {
                  String messageId = widget.message.id;
                  Navigator.of(context).pop();
                  widget.onTransfer(messageId);
                },
              ),
              if (widget.message.contenu.type == MessageType.image ||
                  widget.message.contenu.type == MessageType.fichier ||
                  widget.message.contenu.type == MessageType.audio ||
                  widget.message.contenu.type == MessageType.video)
                ListTile(
                  leading: Icon(Icons.download, color: Colors.orangeAccent),
                  title: Text('Enregistrer'),
                  onTap: () {
                    _saveFile(context);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

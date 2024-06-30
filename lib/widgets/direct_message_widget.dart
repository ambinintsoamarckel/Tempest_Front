import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../models/direct_message.dart';
import '../utils/audio_message_player.dart';
import '../utils/video_message_player.dart';

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
        messageContent = Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: isContact ? Colors.grey[300] : Colors.blue[100],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
              bottomRight: Radius.circular(10.0),
              bottomLeft: isContact ? Radius.circular(10.0) : Radius.circular(0.0),
            ),
          ),
          child: Text(
            message.contenu.texte ?? '',
            style: TextStyle(
              color: isContact ? Colors.blue : Colors.black,
            ),
          ),
        );
        break;
      case MessageType.fichier:
        messageContent = Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: isContact ? Colors.grey[300] : Colors.blue[100],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
              bottomRight: Radius.circular(10.0),
              bottomLeft: isContact ? Radius.circular(10.0) : Radius.circular(0.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.attach_file),
              SizedBox(height: 5),
              Text(
                message.contenu.fichier?.split('/').last ?? '',
                style: TextStyle(
                  color: isContact ? Colors.blue : Colors.black,
                ),
              ),
            ],
          ),
        );
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
        messageContent = AudioMessagePlayer(audioUrl: message.contenu.audio ?? '');
        break;
      case MessageType.video:
        messageContent = VideoMessagePlayer(videoUrl: message.contenu.video ?? '');
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
          elevation: 8.0,
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
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          mainAxisAlignment: isContact ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: <Widget>[
            if (isContact)
              CircleAvatar(
                backgroundImage: contact.photo != null ? NetworkImage(contact.photo!) : null,
              ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: isContact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: <Widget>[
                messageContent,
                SizedBox(height: 5),
                Text(
                  message.dateEnvoi.toLocal().toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveFile(BuildContext context) async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final directory = await getExternalStorageDirectory();
      final filePath = directory?.path ?? '';
      String fileName = '';

      switch (message.contenu.type) {
        case MessageType.image:
          fileName = message.contenu.image?.split('/').last ?? 'image.jpg';
          break;
        case MessageType.audio:
          fileName = message.contenu.audio?.split('/').last ?? 'audio.mp3';
          break;
        case MessageType.video:
          fileName = message.contenu.video?.split('/').last ?? 'video.mp4';
          break;
        case MessageType.fichier:
          fileName = message.contenu.fichier?.split('/').last ?? 'file';
          break;
        default:
          return;
      }

      final fileUrl = _getFileUrl();
      final file = File('$filePath/$fileName');
      final response = await http.get(Uri.parse(fileUrl));
      await file.writeAsBytes(response.bodyBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fichier enregistré sous $fileName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission de stockage refusée')),
      );
    }
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
}

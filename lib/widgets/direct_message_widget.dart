import 'dart:io';
import 'package:flutter/material.dart';
import '../models/direct_message.dart';

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
        messageContent = Text(
          message.contenu.texte ?? '',
          style: TextStyle(
            color: isContact ? Colors.blue : Colors.black,
          ),
        );
        break;
      case MessageType.fichier:
        messageContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.attach_file),
            Text(
              message.contenu.fichier?.split('/').last ?? '',
              style: TextStyle(
                color: isContact ? Colors.blue : Colors.black,
              ),
            ),
          ],
        );
        break;
      case MessageType.image:
        messageContent = Image.file(
          File(message.contenu.image ?? ''),
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
        break;
      case MessageType.audio:
        messageContent = Text('Audio message: ${message.contenu.audio}');
        break;
      case MessageType.video:
        messageContent = Text('Video message: ${message.contenu.video}');
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
            if (message.contenu.type == MessageType.image || message.contenu.type == MessageType.fichier)
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
            onSave!();
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
              backgroundImage: contact.photo != null
                  ? NetworkImage(contact.photo!)
                  : null,
              ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: isContact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: isContact ? Colors.grey[300] : Colors.blue[100],
                    borderRadius: isContact
                        ? BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                            bottomRight: Radius.circular(10.0),
                          )
                        : BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                            bottomLeft: Radius.circular(10.0),
                          ),
                  ),
                  child: messageContent,
                ),
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
}

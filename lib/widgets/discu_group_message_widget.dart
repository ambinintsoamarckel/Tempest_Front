import 'dart:io';
import 'package:flutter/material.dart';
import '../models/discu_group_message.dart'; // Assurez-vous que le chemin est correct

class GroupMessageWidget extends StatelessWidget {
  final GroupMessage message;
  final VoidCallback? onCopy;
  final Function(String) onDelete;
  final Function(String) onTransfer;
  final VoidCallback? onSave;

  GroupMessageWidget({
    required this.message,
    this.onCopy,
    required this.onDelete,
    required this.onTransfer,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    Widget messageContent;

    switch (message.type) {
      case MessageType.text:
        messageContent = Text(
          message.content,
          style: TextStyle(
            color: message.sender == "User 1" ? Colors.blue : Colors.black,
          ),
        );
        break;
      case MessageType.file:
        messageContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.attach_file),
            Text(
              message.content.split('/').last,
              style: TextStyle(
                color: message.sender == "User 1" ? Colors.blue : Colors.black,
              ),
            ),
          ],
        );
        break;
      case MessageType.image:
        messageContent = Image.file(
          File(message.content),
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
        break;
      case MessageType.audio:
        messageContent = Text('Audio message: ${message.content}');
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
                title: Text('Copy'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'transfer',
              child: ListTile(
                leading: Icon(Icons.forward),
                title: Text('Transfer'),
              ),
            ),
            if (message.type == MessageType.image || message.type == MessageType.file)
              PopupMenuItem<String>(
                value: 'save',
                child: ListTile(
                  leading: Icon(Icons.save),
                  title: Text('Save'),
                ),
              ),
          ],
          elevation: 8.0,
        ).then((value) {
          if (value != null) {
            _handleMenuItemSelected(context, value);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: message.sender == "User 1" ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: <Widget>[
            if (message.sender != "User 1")
              Container(
                margin: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(child: Text(message.sender[0])),
              ),
            Column(
              crossAxisAlignment: message.sender == "User 1" ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Text(message.sender, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: messageContent,
                ),
              ],
            ),
            if (message.sender == "User 1")
              Container(
                margin: const EdgeInsets.only(left: 16.0),
                child: CircleAvatar(child: Text(message.sender[0])),
              ),
          ],
        ),
      ),
    );
  }

  void _handleMenuItemSelected(BuildContext context, String value) {
    switch (value) {
      case 'copy':
        if (onCopy != null) onCopy!();
        break;
      case 'delete':
        onDelete(message.id);
        break;
      case 'transfer':
        onTransfer(message.id);
        break;
      case 'save':
        if (onSave != null) onSave!();
        break;
      default:
        break;
    }
  }
}

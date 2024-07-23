import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Pour la gestion des formats de date
import 'package:photo_view/photo_view.dart';
import '../models/direct_message.dart';
import '../utils/audio_message_player.dart';
import '../utils/video_message_player.dart';
import '../utils/downloader.dart';

class DirectMessageWidget extends StatefulWidget {
  final DirectMessage message;
  final User contact;
  final VoidCallback onCopy;
  final Function(String) onDelete;
  final Function(String) onTransfer;
  final DateTime? previousMessageDate;

  const DirectMessageWidget({super.key, 
    required this.message,
    required this.contact,
    required this.onCopy,
    required this.onDelete,
    required this.onTransfer,
    this.previousMessageDate,
  });

  @override
  _DirectMessageWidgetState createState() => _DirectMessageWidgetState();
}

class _DirectMessageWidgetState extends State<DirectMessageWidget> {
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isContact = widget.message.expediteur.id == widget.contact.id;
    Widget messageContent;

    switch (widget.message.contenu.type) {
      case MessageType.texte:
        messageContent = _buildTextMessage(context, isContact);
        break;
      case MessageType.fichier:
        messageContent = _buildFileMessage(context, isContact);
        break;
      case MessageType.image:
        messageContent = _buildImageMessage(context, isContact);
        break;
      case MessageType.audio:
        messageContent = _buildAudioMessage(context, isContact);
        break;
      case MessageType.video:
        messageContent = _buildVideoMessage(context, isContact);
        break;
      default:
        messageContent = const Text('Unsupported message type');
    }

    final messageDate = DateTime(
      widget.message.dateEnvoi.year,
      widget.message.dateEnvoi.month,
      widget.message.dateEnvoi.day,
    );

    return Column(
      children: [
        GestureDetector(
          onLongPress: () {
            _showMessageOptions(context);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              mainAxisAlignment: isContact ? MainAxisAlignment.start : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (isContact) ...[
                  CircleAvatar(
                    backgroundImage: widget.contact.photo != null ? NetworkImage(widget.contact.photo!) : null,
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                          decoration: BoxDecoration(
                            color: isContact ? Colors.grey[300] : Colors.green[100],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(10.0),
                              topRight: const Radius.circular(10.0),
                              bottomRight: const Radius.circular(10.0),
                              bottomLeft: isContact ? const Radius.circular(10.0) : const Radius.circular(0.0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              messageContent,
                            ],
                          ),
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
                              if (!isContact) _buildReadStatus(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isContact)
                  const SizedBox(width: 5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextMessage(BuildContext context, bool isContact) {
    return Text(
      widget.message.contenu.texte ?? '',
      style: const TextStyle(
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
        const Icon(Icons.attach_file),
        const SizedBox(width: 5),
        Text(
          widget.message.contenu.fichier?.split('/').last ?? '',
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildImageMessage(BuildContext context, bool isContact) {
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

  Widget _buildAudioMessage(BuildContext context, bool isContact) {
    return AudioMessagePlayer(audioUrl: widget.message.contenu.audio ?? '');
  }

  Widget _buildVideoMessage(BuildContext context, bool isContact) {
    return VideoMessagePlayer(videoUrl: widget.message.contenu.video ?? '');
  }

  String _formatDate(DateTime date) {
    final DateTime adjustedDate = date.add(const Duration(hours: 3)); // Ajouter 3 heures pour GMT+3
    return DateFormat.Hm().format(adjustedDate); // Heure si aujourd'hui
  }

  Widget _buildReadStatus() {
    return widget.message.lu ? const Icon(Icons.done_all, color: Colors.blue) : const Icon(Icons.done, color: Colors.grey);
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
              backgroundDecoration: const BoxDecoration(
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.message.contenu.type == MessageType.texte)
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.blueAccent),
                  title: const Text('Copier'),
                  onTap: () {
                    widget.onCopy();
                    Navigator.of(context).pop();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Supprimer'),
                onTap: () {
                  widget.onDelete(widget.message.id);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward, color: Colors.greenAccent),
                title: const Text('Transférer'),
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
                  leading: const Icon(Icons.download, color: Colors.orangeAccent),
                  title: const Text('Enregistrer'),
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

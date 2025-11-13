// lib/widgets/messages/group_message_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import 'package:mini_social_network/models/group_message.dart';
import 'package:mini_social_network/utils/downloader.dart';
import 'message_avatar.dart';
import 'message_content/text_message.dart';
import 'message_content/file_message.dart';
import 'message_content/image_message.dart';
import 'message_content/audio_message.dart';
import 'message_content/video_message.dart';
import 'message_content/unsupported_message.dart';
import 'message_footer.dart';
import 'message_options_sheet.dart';

class GroupMessageWidget extends StatefulWidget {
  final GroupMessage message;
  final String currentUser;
  final VoidCallback? onCopy;
  final Function(String) onDelete;
  final Function(String) onTransfer;
  final VoidCallback? onSave;

  const GroupMessageWidget({
    super.key,
    required this.message,
    required this.currentUser,
    this.onCopy,
    required this.onDelete,
    required this.onTransfer,
    this.onSave,
  });

  @override
  State<GroupMessageWidget> createState() => _GroupMessageWidgetState();
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
    final isCurrentUser = widget.message.expediteur.id == widget.currentUser;
    final isNotification = widget.message.notification;

    if (isNotification) {
      return _buildNotification();
    }

    // --- Contenu du message ---
    Widget content = _buildContent(isCurrentUser);

    return GestureDetector(
      onLongPress: () => MessageOptionsSheet.show(
        context,
        message: widget.message,
        isContact: !isCurrentUser,
        onCopy: widget.onCopy ?? () {},
        onTransfer: widget.onTransfer,
        onDelete: widget.onDelete,
        onSave: widget.onSave ?? () {},
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser) ...[
              MessageAvatar(contact: widget.message.expediteur),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                child: Column(
                  crossAxisAlignment: isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Nom de l'expéditeur (uniquement si contact)
                    if (!isCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 2),
                        child: Text(
                          widget.message.expediteur.nom ?? 'Anonyme',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                      ),
                    content,
                    const SizedBox(height: 4),
                    MessageFooter(
                      date: widget.message.dateEnvoi,
                      isContact: !isCurrentUser,
                      isSending: false,
                      sendFailed: false,
                      isRead: widget.message.luPar?.isNotEmpty ?? false,
                      isGroup: true, // Pour afficher done_all si luPar non vide
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isCurrentUser) {
    switch (widget.message.contenu.type) {
      case MessageType.texte:
        return TextMessage(
            text: widget.message.contenu.texte ?? '',
            isContact: !isCurrentUser);
      case MessageType.fichier:
        return FileMessage(
            fileUrl: widget.message.contenu.fichier ?? '',
            isContact: !isCurrentUser);
      case MessageType.image:
        return ImageMessage(
          imageUrl: widget.message.contenu.image ?? '',
          messageId: widget.message.id,
          onSave: widget.onSave != null ? () => _saveFile(context) : null,
        );
      case MessageType.audio:
        return AudioMessage(audioUrl: widget.message.contenu.audio ?? '');
      case MessageType.video:
        return VideoMessage(videoUrl: widget.message.contenu.video ?? '');
      default:
        return const UnsupportedMessage();
    }
  }

  Widget _buildNotification() {
    final content = widget.message.contenu.texte ?? '';
    final isCurrentUser =
        widget.message.expediteur.id == widget.currentUser; // RECALCULÉ ICI
    final display = isCurrentUser
        ? 'Vous avez $content'
        : '${widget.message.expediteur.nom} a $content';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          display,
          style: const TextStyle(
              fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Future<void> _saveFile(BuildContext context) async {
    final url = _getFileUrl();
    if (url.isEmpty) return;

    try {
      await downloadFile(_scaffoldMessenger!, url, _getFileType());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec du téléchargement')),
      );
    }
  }

  String _getFileUrl() {
    return switch (widget.message.contenu.type) {
      MessageType.image => widget.message.contenu.image ?? '',
      MessageType.audio => widget.message.contenu.audio ?? '',
      MessageType.video => widget.message.contenu.video ?? '',
      MessageType.fichier => widget.message.contenu.fichier ?? '',
      _ => '',
    };
  }

  String _getFileType() {
    return switch (widget.message.contenu.type) {
      MessageType.image => "image",
      MessageType.audio => "audio",
      MessageType.video => "video",
      MessageType.fichier => "file",
      _ => "file",
    };
  }
}

// lib/widgets/messages/direct_message_widget.dart
import 'package:flutter/material.dart';
import '../../models/direct_message.dart';
import '../../utils/downloader.dart';
import '../../theme/app_theme.dart';
import 'message_avatar.dart';
import 'message_content/text_message.dart';
import 'message_content/file_message.dart';
import 'message_content/image_message.dart';
import 'message_content/audio_message.dart';
import 'message_content/video_message.dart';
import 'message_content/unsupported_message.dart';
import 'message_footer.dart';
import 'message_options_sheet.dart';

class DirectMessageWidget extends StatefulWidget {
  final DirectMessage message;
  final User contact;
  final VoidCallback onCopy;
  final Function(String) onDelete;
  final Function(String) onTransfer;
  final DateTime? previousMessageDate;
  final bool? isSending;
  final bool? sendFailed;

  const DirectMessageWidget({
    super.key,
    required this.message,
    required this.contact,
    required this.onCopy,
    required this.onDelete,
    required this.onTransfer,
    this.previousMessageDate,
    this.isSending,
    this.sendFailed,
  });

  @override
  State<DirectMessageWidget> createState() => _DirectMessageWidgetState();
}

class _DirectMessageWidgetState extends State<DirectMessageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isContact = widget.message.expediteur.id == widget.contact.id;

    Widget content;
    switch (widget.message.contenu.type) {
      case MessageType.texte:
        content = TextMessage(
            text: widget.message.contenu.texte ?? '', isContact: isContact);
        break;
      case MessageType.fichier:
        content = FileMessage(
            fileUrl: widget.message.contenu.fichier ?? '',
            isContact: isContact);
        break;
      case MessageType.image:
        content = ImageMessage(
          imageUrl: widget.message.contenu.image ?? '',
          messageId: widget.message.id,
          onSave: () => _saveFile(context),
        );
        break;
      case MessageType.audio:
        content = AudioMessage(audioUrl: widget.message.contenu.audio ?? '');
        break;
      case MessageType.video:
        content = VideoMessage(videoUrl: widget.message.contenu.video ?? '');
        break;
      default:
        content = const UnsupportedMessage();
    }

    return Opacity(
      opacity: widget.isSending == true ? 0.6 : 1.0,
      child: GestureDetector(
        onLongPress: widget.isSending == true
            ? null
            : () => MessageOptionsSheet.show(
                  context,
                  message: widget.message,
                  isContact: isContact,
                  onCopy: widget.onCopy,
                  onTransfer: widget.onTransfer,
                  onDelete: widget.onDelete,
                  onSave: () => _saveFile(context),
                ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment:
                isContact ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isContact) ...[
                MessageAvatar(contact: widget.contact),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: Column(
                    crossAxisAlignment: isContact
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      Stack(
                        children: [
                          content,
                          if (widget.isSending == true &&
                              widget.message.contenu.type != MessageType.texte)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      MessageFooter(
                        date: widget.message.dateEnvoi,
                        isContact: isContact,
                        isSending: widget.isSending,
                        sendFailed: widget.sendFailed,
                        isRead: widget.message.lu,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveFile(BuildContext context) async {
    final fileUrl = _getFileUrl();
    if (fileUrl.isEmpty) {
      _showSnackBar(context, 'Aucun fichier à télécharger', isError: true);
      return;
    }

    try {
      await downloadFile(
          ScaffoldMessenger.of(context), fileUrl, _getFileType());
      _showSnackBar(context, 'Téléchargement démarré', isError: false);
    } catch (e) {
      _showSnackBar(context, 'Échec du téléchargement', isError: true);
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

  void _showSnackBar(BuildContext context, String message,
      {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle,
                color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor:
            isError ? AppTheme.accentColor : AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// lib/widgets/messages/group_message_widget.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
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
import 'package:mini_social_network/models/message_content.dart';

class GroupMessageWidget extends StatefulWidget {
  final GroupMessage message;
  final String currentUser;
  final VoidCallback? onCopy;
  final Future<void> Function(String) onDelete;
  final Function(String) onTransfer;
  final VoidCallback? onSave;
  final bool? isSending;
  final bool? sendFailed;

  const GroupMessageWidget({
    super.key,
    required this.message,
    required this.currentUser,
    this.onCopy,
    required this.onDelete,
    required this.onTransfer,
    this.onSave,
    this.isSending,
    this.sendFailed,
  });

  @override
  State<GroupMessageWidget> createState() => _GroupMessageWidgetState();
}

class _GroupMessageWidgetState extends State<GroupMessageWidget> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = widget.message.expediteur.id == widget.currentUser;
    final isNotification = widget.message.notification;

    if (isNotification) {
      return _buildNotification();
    }

    Widget content = _buildContent(isCurrentUser);

    // ✅ Applique l'opacité si en cours d'envoi (comme DirectMessage)
    return Opacity(
      opacity: widget.isSending == true ? 0.6 : 1.0,
      child: GestureDetector(
        // ✅ Désactive long press si en cours d'envoi
        onLongPress: widget.isSending == true
            ? null
            : () => MessageOptionsSheet.show(
                  context,
                  message: widget.message,
                  isContact: !isCurrentUser,
                  onCopy: widget.onCopy ?? () {},
                  onTransfer: widget.onTransfer,
                  onDelete: widget.onDelete,
                  onSave: () => _saveFile(context),
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
                      // ✅ Ajoute un Stack avec loader pour les fichiers (comme DirectMessage)
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
                      // ✅ FIX: Utilise les props au lieu de hardcoder
                      MessageFooter(
                        date: widget.message.dateEnvoi,
                        isContact: !isCurrentUser,
                        isSending: widget.isSending,
                        sendFailed: widget.sendFailed,
                        isRead: widget.message.luPar?.isNotEmpty ?? false,
                        isGroup: true,
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

  Widget _buildContent(bool isCurrentUser) {
    switch (widget.message.contenu.type) {
      case MessageType.texte:
        return TextMessage(
            text: widget.message.contenu.texte ?? '',
            isContact: !isCurrentUser);
      case MessageType.fichier:
        return FileMessage(
          fileUrl: widget.message.contenu.fichier ?? '',
          isContact: !isCurrentUser,
          onSave: () => _saveFile(context),
        );
      case MessageType.image:
        return ImageMessage(
          imageUrl: widget.message.contenu.image ?? '',
          messageId: widget.message.id,
          onSave: () => _saveFile(context),
        );
      case MessageType.audio:
        return AudioMessage(
          audioUrl: widget.message.contenu.audio ?? '',
          isContact: !isCurrentUser,
        );
      case MessageType.video:
        return VideoMessage(
          videoUrl: widget.message.contenu.video ?? '',
          onSave: () => _saveFile(context),
        );
      default:
        return const UnsupportedMessage();
    }
  }

  Widget _buildNotification() {
    final content = widget.message.contenu.texte ?? '';
    final isCurrentUser = widget.message.expediteur.id == widget.currentUser;
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
    if (_isDownloading) {
      _showSnackBar(context, 'Téléchargement déjà en cours', isError: true);
      return;
    }

    final fileUrl = _getFileUrl();
    if (fileUrl.isEmpty) {
      _showSnackBar(context, 'Aucun fichier à télécharger', isError: true);
      return;
    }

    setState(() => _isDownloading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    _showSnackBar(context, 'Téléchargement en cours...',
        isError: false, isLoading: true);

    try {
      final filePath = await downloadFile(fileUrl, _getFileType());
      scaffoldMessenger.clearSnackBars();

      final fileName = filePath.split('/').last;
      _showSnackBar(context, 'Téléchargé : $fileName', isError: false);
    } catch (e) {
      scaffoldMessenger.clearSnackBars();

      String errorMessage = 'Échec du téléchargement';
      if (e.toString().contains('Permission')) {
        errorMessage = 'Permission de stockage refusée';
      } else if (e.toString().contains('Code')) {
        errorMessage = 'Fichier introuvable sur le serveur';
      }

      _showSnackBar(context, errorMessage, isError: true);
      print('❌ Erreur téléchargement: $e');
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
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

  void _showSnackBar(
    BuildContext context,
    String message, {
    required bool isError,
    bool isLoading = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(
                isError ? Icons.error_outline : Icons.check_circle,
                color: Colors.white,
              ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? AppTheme.accentColor
            : (isLoading ? Colors.blue : AppTheme.secondaryColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(top: 100, left: 16, right: 16),
        duration: Duration(seconds: isLoading ? 30 : 1),
      ),
    );
  }
}

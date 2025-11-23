// lib/widgets/messages/group_message_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
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
  // ✅ Flag pour bloquer les téléchargements multiples
  bool _isDownloading = false;

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
        onSave: () => _saveFile(context), // ✅ Utilise la nouvelle méthode
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
                      isGroup: true,
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
          isContact: !isCurrentUser,
          onSave: () => _saveFile(context), // ✅ Ajout du callback
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
        return VideoMessage(videoUrl: widget.message.contenu.video ?? '');
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

  // ✅ NOUVELLE VERSION : Gère les notifications proprement + bloque les téléchargements multiples
  Future<void> _saveFile(BuildContext context) async {
    // ✅ Bloquer si un téléchargement est déjà en cours
    if (_isDownloading) {
      _showSnackBar(context, 'Téléchargement déjà en cours', isError: true);
      return;
    }

    final fileUrl = _getFileUrl();
    if (fileUrl.isEmpty) {
      _showSnackBar(context, 'Aucun fichier à télécharger', isError: true);
      return;
    }

    // ✅ Marquer comme "en cours de téléchargement"
    setState(() => _isDownloading = true);

    // ✅ Garder une référence au ScaffoldMessenger
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // ✅ Afficher "Téléchargement en cours..." AVANT
    _showSnackBar(context, 'Téléchargement en cours...',
        isError: false, isLoading: true);

    try {
      // ✅ Télécharger le fichier
      final filePath = await downloadFile(fileUrl, _getFileType());

      // ✅ FERMER immédiatement le SnackBar "en cours"
      scaffoldMessenger.clearSnackBars();

      // ✅ Extraire le nom du fichier
      final fileName = filePath.split('/').last;

      // ✅ Afficher le succès
      _showSnackBar(
        context,
        'Téléchargé : $fileName',
        isError: false,
      );
    } catch (e) {
      // ✅ FERMER immédiatement le SnackBar "en cours"
      scaffoldMessenger.clearSnackBars();

      // ✅ Gérer les erreurs
      String errorMessage = 'Échec du téléchargement';

      if (e.toString().contains('Permission')) {
        errorMessage = 'Permission de stockage refusée';
      } else if (e.toString().contains('Code')) {
        errorMessage = 'Fichier introuvable sur le serveur';
      }

      _showSnackBar(context, errorMessage, isError: true);
      print('❌ Erreur téléchargement: $e');
    } finally {
      // ✅ Toujours débloquer à la fin
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
        // ✅ Positionner en HAUT pour ne pas bloquer l'input area
        margin: const EdgeInsets.only(top: 100, left: 16, right: 16),
        duration: Duration(seconds: isLoading ? 30 : 1),
      ),
    );
  }
}

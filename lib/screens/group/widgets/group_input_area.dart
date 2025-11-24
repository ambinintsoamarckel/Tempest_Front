// lib/screens/group/widgets/group_input_area.dart
import 'package:flutter/material.dart';
import 'package:mini_social_network/widgets/voice_recording_widget.dart';
import 'package:mini_social_network/screens/direct/widgets/attachment_menu.dart';
import 'package:mini_social_network/theme/app_theme.dart';
import 'package:mini_social_network/screens/group/services/group_chat_controller.dart';
import 'package:mini_social_network/models/attachment_option.dart';

class GroupInputArea extends StatelessWidget {
  final GroupChatController controller;

  const GroupInputArea({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Bloquer le champ texte si un fichier est en preview
    final bool isTextFieldBlocked = controller.previewFile != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        children: [
          if (controller.showAttachmentMenu)
            AttachmentMenu(
              options: [
                AttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  color: AppTheme.primaryColor,
                  onTap: controller.pickImage,
                ),
                AttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  color: AppTheme.secondaryColor,
                  onTap: controller.takePhoto,
                ),
                AttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Fichier',
                  color: AppTheme.accentColor,
                  onTap: controller.pickFile,
                ),
              ],
            ),
          Row(
            children: [
              // ✅ Masquer le bouton + quand un fichier est en preview
              if (!isTextFieldBlocked)
                IconButton(
                  icon: Icon(
                    controller.showAttachmentMenu
                        ? Icons.close
                        : Icons.add_circle_outline,
                  ),
                  onPressed: controller.toggleAttachmentMenu,
                ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isTextFieldBlocked
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? const Color(
                                0xFF1C1C1C) // ✅ Plus sombre si bloqué (dark mode)
                            : Colors.grey
                                .shade200) // ✅ Plus gris si bloqué (light mode)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2C2C2C)
                            : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: controller.textController,
                    enabled:
                        !isTextFieldBlocked, // ✅ Désactivé si fichier présent
                    onSubmitted: (_) => _handleSend(context),
                    style: TextStyle(
                      color: isTextFieldBlocked
                          ? Colors.grey.shade500 // ✅ Texte grisé si bloqué
                          : null,
                    ),
                    decoration: InputDecoration(
                      hintText: _getHintText(), // ✅ Hint dynamique
                      hintStyle: TextStyle(
                        color: isTextFieldBlocked
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    maxLines: null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildSendButton(context),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Hint dynamique selon le type de preview
  String _getHintText() {
    if (controller.previewFile == null) {
      return "Message du groupe";
    }

    switch (controller.previewType) {
      case 'image':
        return "Image prête à envoyer";
      case 'video':
        return "Vidéo prête à envoyer";
      case 'audio':
        return "Audio prêt à envoyer";
      case 'file':
        return "Fichier prêt à envoyer";
      default:
        return "Fichier prêt à envoyer";
    }
  }

  Widget _buildSendButton(BuildContext context) {
    // Si un fichier est en preview -> bouton send
    if (controller.previewFile != null) {
      return GestureDetector(
        onTap: () => controller.sendFile(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.send,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }

    // Si du texte est présent -> bouton send
    if (controller.hasText) {
      return GestureDetector(
        onTap: () => controller.sendText(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.send,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }

    // Sinon -> bouton micro
    return VoiceRecordingButton(
      isRecording: controller.isRecording,
      onStartRecording: controller.startRecording,
      useModernMode: true,
    );
  }

  void _handleSend(BuildContext context) {
    // Cette méthode n'est appelée que par onSubmitted du TextField
    // Donc uniquement quand pas de fichier
    if (controller.hasText && controller.previewFile == null) {
      controller.sendText(context);
    }
  }
}


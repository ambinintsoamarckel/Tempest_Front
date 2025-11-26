import 'package:flutter/material.dart';
import 'package:mini_social_network/widgets/voice_recording_widget.dart';
import 'attachment_menu.dart';
import 'package:mini_social_network/theme/app_theme.dart';
import 'package:mini_social_network/screens/direct/services/direct_chat_controller.dart';
import 'package:mini_social_network/models/attachment_option.dart';

class DirectInputArea extends StatelessWidget {
  final DirectChatController controller;

  const DirectInputArea({
    super.key,
    required this.controller,
  });

  // --- Widgets qui dépendent UNIQUEMENT de l'état du contrôleur de texte/fichier ---

  Widget _buildTextField(BuildContext context, bool isTextFieldBlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isTextFieldBlocked
            ? (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1C)
                : Colors.grey.shade200)
            : (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2C2C2C)
                : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller.textController,
        // ✅ IMPORTANT : Le TextField gère sa propre reconstruction du texte.
        // On n'a pas besoin de rebuild le parent pour cela.
        enabled: !isTextFieldBlocked,
        onSubmitted: (_) => _handleSend(context),
        style: TextStyle(
          color: isTextFieldBlocked ? Colors.grey.shade500 : null,
        ),
        decoration: InputDecoration(
          hintText: _getHintText(),
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
    );
  }

  // Ce widget utilise ValueListenableBuilder pour écouter le contrôleur de texte
  // et ne reconstruire QUE le bouton d'envoi/micro.
  Widget _buildSendButton(BuildContext context) {
    // ValueListenableBuilder écoute les changements de la propriété 'value'
    // du TextEditingController sans rebuild le DirectInputArea entier.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.textController,
      builder: (context, value, child) {
        final bool isTextPresent = value.text.trim().isNotEmpty;

        // 1. Si un fichier est en preview (cette vérification ne change que via un autre notifier)
        if (controller.previewFile != null) {
          return GestureDetector(
            onTap: () => controller.sendFile(context),
            child: _SendButtonIcon(),
          );
        }

        // 2. Si du texte est présent -> bouton send
        if (isTextPresent) {
          return GestureDetector(
            onTap: () => controller.sendText(context),
            child: _SendButtonIcon(),
          );
        }

        // 3. Sinon -> bouton micro
        // NOTE: Si controller.isRecording est un autre état géré par un ChangeNotifier,
        // vous devrez envelopper VoiceRecordingButton dans un Consumer/Listener
        // de ce ChangeNotifier pour qu'il se mette à jour correctement.
        return VoiceRecordingButton(
          isRecording: controller.isRecording,
          onStartRecording: controller.startRecording,
          useModernMode: true,
        );
      },
    );
  }

  // Widget interne pour le style du bouton d'envoi
  Widget _SendButtonIcon() {
    return Container(
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
    );
  }

  // ✅ NOUVEAU : Hint dynamique selon le type de preview
  String _getHintText() {
    if (controller.previewFile == null) {
      return "Message";
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

  void _handleSend(BuildContext context) {
    // Cette méthode n'est appelée que par onSubmitted du TextField
    if (controller.textController.text.trim().isNotEmpty &&
        controller.previewFile == null) {
      controller.sendText(context);
    }
  }

  // --- Méthode Build Principale ---

  @override
  Widget build(BuildContext context) {
    // Si vous utilisez un package de gestion d'état, ce widget devrait
    // être enveloppé pour écouter les changements sur `showAttachmentMenu`
    // et `previewFile` uniquement (pas le texte).

    // Pour l'instant, on assume que tout changement dans le DirectChatController
    // déclenche un rebuild de DirectInputArea (via un Consumer ou autre dans le parent).
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
          // L'AttachmentMenu se reconstruit si showAttachmentMenu change
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
                child: _buildTextField(context, isTextFieldBlocked),
              ),
              const SizedBox(width: 4),
              // ✅ Utilise ValueListenableBuilder pour la reconstruction isolée
              _buildSendButton(context),
            ],
          ),
        ],
      ),
    );
  }
}

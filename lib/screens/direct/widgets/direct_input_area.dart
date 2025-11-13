// lib/screens/direct/widgets/direct_input_area.dart
import 'package:flutter/material.dart';
import 'package:mini_social_network/widgets/voice_recording_widget.dart';
import 'attachment_menu.dart';
import 'package:mini_social_network/theme/app_theme.dart';
import 'package:mini_social_network/screens/direct/services/direct_chat_controller.dart';

class DirectInputArea extends StatelessWidget {
  final DirectChatController controller;

  const DirectInputArea({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2C2C2C)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: controller.textController,
                    onSubmitted: (_) => controller.sendText(context),
                    decoration: const InputDecoration(
                      hintText: "Message",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    maxLines: null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              controller.hasText
                  ? GestureDetector(
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
                    )
                  : VoiceRecordingButton(
                      isRecording: controller.isRecording,
                      onStartRecording: controller.startRecording,
                      useModernMode: true,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class AttachmentOption {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

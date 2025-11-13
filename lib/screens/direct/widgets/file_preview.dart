// lib/screens/direct/widgets/file_preview.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mini_social_network/theme/app_theme.dart';

class FilePreview extends StatelessWidget {
  final File file;
  final String type;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const FilePreview(
      {super.key,
      required this.file,
      required this.type,
      required this.onCancel,
      required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.previewContainerDecoration(context),
      child: Row(
        children: [
          _thumbnail(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.path.split('/').last,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionButton(Icons.close, AppTheme.accentColor, onCancel),
                    const SizedBox(width: 12),
                    _actionButton(Icons.send, AppTheme.secondaryColor, onSend),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnail() {
    if (type == 'image')
      return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover));
    if (type == 'audio')
      return _iconContainer(Icons.audiotrack, AppTheme.primaryColor);
    return _iconContainer(Icons.insert_drive_file, AppTheme.secondaryColor);
  }

  Widget _iconContainer(IconData icon, Color color) => Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 40, color: color));

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) =>
      Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: color, size: 20))),
      );
}

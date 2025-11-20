// lib/widgets/messages/message_content/file_message.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class FileMessage extends StatelessWidget {
  final String fileUrl;
  final bool isContact;
  final VoidCallback? onSave;

  const FileMessage({
    super.key,
    required this.fileUrl,
    required this.isContact,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = fileUrl.split('/').last;

    return GestureDetector(
      onTap: onSave,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isContact
              ? Colors.grey.shade200
              : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isContact
                ? Colors.grey.shade300
                : AppTheme.primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isContact
                    ? Colors.grey.shade300
                    : AppTheme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getFileIcon(fileName),
                color: isContact ? Colors.grey.shade700 : AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      color: isContact ? Colors.black87 : AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Appuyer pour télécharger',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.download_rounded,
              color: isContact ? Colors.grey.shade600 : AppTheme.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      // Documents
      'pdf' => Icons.picture_as_pdf,
      'doc' || 'docx' => Icons.description,
      'txt' => Icons.text_snippet,
      'rtf' => Icons.text_fields,

      // Tableurs
      'xls' || 'xlsx' || 'csv' => Icons.table_chart,

      // Présentations
      'ppt' || 'pptx' => Icons.slideshow,

      // Archives
      'zip' || 'rar' || '7z' || 'tar' || 'gz' => Icons.folder_zip,

      // Code
      'html' || 'css' || 'js' || 'jsx' => Icons.code,
      'dart' || 'java' || 'py' || 'cpp' || 'c' => Icons.code,
      'json' || 'xml' || 'yaml' => Icons.data_object,

      // Images (au cas où)
      'jpg' || 'jpeg' || 'png' || 'gif' || 'svg' => Icons.image,

      // Audio
      'mp3' || 'wav' || 'ogg' || 'flac' => Icons.audio_file,

      // Vidéo
      'mp4' || 'avi' || 'mov' || 'mkv' => Icons.video_file,

      // Exécutables/Apps
      'exe' || 'apk' || 'dmg' => Icons.apps,

      // Défaut
      _ => Icons.insert_drive_file,
    };
  }
}

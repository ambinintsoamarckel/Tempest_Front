// lib/widgets/messages/message_content/file_message.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class FileMessage extends StatelessWidget {
  final String fileUrl;
  final bool isContact;

  const FileMessage(
      {super.key, required this.fileUrl, required this.isContact});

  @override
  Widget build(BuildContext context) {
    final fileName = fileUrl.split('/').last;

    return Container(
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.download_rounded,
              color: isContact ? Colors.grey.shade600 : AppTheme.primaryColor,
              size: 20),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf,
      'doc' || 'docx' => Icons.description,
      'xls' || 'xlsx' => Icons.table_chart,
      'zip' || 'rar' => Icons.folder_zip,
      _ => Icons.insert_drive_file,
    };
  }
}

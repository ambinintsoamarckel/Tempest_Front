// lib/screens/direct/widgets/file_preview.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mini_social_network/theme/app_theme.dart';
import 'package:mini_social_network/widgets/audio_player_widget.dart'; // ✅ Import du nouveau widget

class FilePreview extends StatelessWidget {
  final File file;
  final String type;
  final VoidCallback onCancel;

  const FilePreview({
    super.key,
    required this.file,
    required this.type,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = file.path.split('/').last;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Bouton fermer à gauche
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCancel,
            tooltip: 'Annuler',
          ),
          const SizedBox(width: 8),

          // Preview du fichier
          Expanded(
            child: type == 'audio'
                ? AudioPlayerWidget(
                    audioFile: file,
                    primaryColor: AppTheme.primaryColor,
                    showFileName: true,
                  )
                : _FilePreviewContent(
                    file: file,
                    type: type,
                    fileName: fileName,
                  ),
          ),
        ],
      ),
    );
  }

  /// Détection du vrai type selon l'extension (statique pour usage externe)
  static String detectFileType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();

    // Images
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].contains(ext)) {
      return 'image';
    }

    // Audio
    if (['mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac', 'wma'].contains(ext)) {
      return 'audio';
    }

    // Vidéo
    if (['mp4', 'avi', 'mov', 'mkv', 'flv', 'wmv', 'webm', 'm4v']
        .contains(ext)) {
      return 'video';
    }

    // Sinon c'est un fichier générique
    return 'file';
  }
}

/// Preview pour fichiers normaux (image/video/file)
class _FilePreviewContent extends StatelessWidget {
  final File file;
  final String type;
  final String fileName;

  const _FilePreviewContent({
    required this.file,
    required this.type,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail ou icône
          _buildThumbnail(),
          const SizedBox(width: 12),

          // Infos fichier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getFileSize(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    // Vérifier si c'est une image (par type OU par extension)
    final isImage = type == 'image' || _isImageFile(fileName);

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildIconThumbnail(Icons.image, AppTheme.primaryColor);
          },
        ),
      );
    }

    // Sinon, afficher l'icône correspondante
    final icon = _getFileIcon(fileName);
    final color =
        type == 'video' ? AppTheme.secondaryColor : AppTheme.primaryColor;
    return _buildIconThumbnail(icon, color);
  }

  Widget _buildIconThumbnail(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 28, color: color),
    );
  }

  bool _isImageFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].contains(ext);
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

      // Images
      'jpg' || 'jpeg' || 'png' || 'gif' || 'svg' => Icons.image,

      // Vidéo
      'mp4' || 'avi' || 'mov' || 'mkv' => Icons.video_file,

      // Exécutables
      'exe' || 'apk' || 'dmg' => Icons.apps,

      // Défaut
      _ => Icons.insert_drive_file,
    };
  }

  String _getFileSize() {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Fichier';
    }
  }
}

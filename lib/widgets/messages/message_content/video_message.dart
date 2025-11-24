// lib/widgets/messages/message_content/video_message.dart
import 'package:flutter/material.dart';
import '../../../utils/video_message_player.dart';

class VideoMessage extends StatelessWidget {
  final String videoUrl;
  final VoidCallback? onSave;

  const VideoMessage({
    super.key,
    required this.videoUrl,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: VideoMessagePlayer(
          videoUrl: videoUrl,
          onSave: onSave,
        ),
      ),
    );
  }
}

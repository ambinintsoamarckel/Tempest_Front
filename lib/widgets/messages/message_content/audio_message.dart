// lib/widgets/messages/message_content/audio_message.dart
import 'package:flutter/material.dart';
import '../../../utils/audio_message_player.dart';

class AudioMessage extends StatelessWidget {
  final String audioUrl;

  const AudioMessage({super.key, required this.audioUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: AudioMessagePlayer(audioUrl: audioUrl),
    );
  }
}

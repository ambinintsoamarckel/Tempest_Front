// lib/widgets/messages/message_content/audio_message.dart
import 'package:flutter/material.dart';
import '../../../utils/audio_message_player.dart';

class AudioMessage extends StatelessWidget {
  final String audioUrl;
  final bool isContact;

  const AudioMessage({
    super.key,
    required this.audioUrl,
    this.isContact = true,
  });

  @override
  Widget build(BuildContext context) {
    return AudioMessagePlayer(
      audioUrl: audioUrl,
      isContact: isContact,
    );
  }
}

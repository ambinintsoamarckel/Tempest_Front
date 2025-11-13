// lib/screens/direct/widgets/optimistic_message_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mini_social_network/screens/direct/services/direct_chat_controller.dart';
import 'package:mini_social_network/theme/app_theme.dart';

class OptimisticMessageWidget extends StatelessWidget {
  final OptimisticMessage message;
  final String contactId;

  const OptimisticMessageWidget({
    super.key,
    required this.message,
    required this.contactId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: message.isFailed
                      ? [Colors.red.shade300, Colors.red.shade400]
                      : [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.text != null) _buildTextMessage(),
                  if (message.file != null) _buildFileMessage(),
                  const SizedBox(height: 4),
                  _buildStatusIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage() {
    return Text(
      message.text!,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
      ),
    );
  }

  Widget _buildFileMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.fileType == 'image')
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Image.file(
                  message.file!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                if (message.isSending && message.uploadProgress != null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: message.uploadProgress,
                          backgroundColor: Colors.white30,
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  message.fileType == 'audio'
                      ? Icons.audiotrack
                      : Icons.insert_drive_file,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.file!.path.split('/').last,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (message.isSending && message.uploadProgress != null)
                      Column(
                        children: [
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: message.uploadProgress,
                            backgroundColor: Colors.white30,
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(message.uploadProgress! * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    if (message.isFailed) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.white70),
          SizedBox(width: 4),
          Text(
            'Non envoyé',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    if (message.isSending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation(Colors.white70),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Envoi...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    // Sent
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done_all, size: 16, color: Colors.white),
        SizedBox(width: 4),
        Text(
          'Envoyé',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

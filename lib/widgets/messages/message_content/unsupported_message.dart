// lib/widgets/messages/message_content/unsupported_message.dart
import 'package:flutter/material.dart';

class UnsupportedMessage extends StatelessWidget {
  const UnsupportedMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text('Type de message non supporté',
              style: TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}

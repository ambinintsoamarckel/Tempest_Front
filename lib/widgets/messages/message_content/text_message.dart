// lib/widgets/messages/message_content/text_message.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class TextMessage extends StatelessWidget {
  final String text;
  final bool isContact;

  const TextMessage({super.key, required this.text, required this.isContact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
      decoration: BoxDecoration(
        gradient: isContact
            ? LinearGradient(
                colors: [Colors.grey.shade200, Colors.grey.shade100])
            : const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomRight:
              isContact ? const Radius.circular(16) : const Radius.circular(4),
          bottomLeft:
              isContact ? const Radius.circular(4) : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: (isContact ? Colors.grey : AppTheme.primaryColor)
                .withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
            color: isContact ? Colors.black87 : Colors.white,
            fontSize: 15,
            height: 1.4),
        softWrap: true,
      ),
    );
  }
}

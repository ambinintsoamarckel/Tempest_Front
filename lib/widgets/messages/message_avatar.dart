// lib/widgets/messages/message_avatar.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/direct_message.dart';

class MessageAvatar extends StatelessWidget {
  final User contact;

  const MessageAvatar({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        backgroundImage:
            contact.photo != null ? NetworkImage(contact.photo!) : null,
        child: contact.photo == null
            ? Text(
                contact.nom.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : null,
      ),
    );
  }
}

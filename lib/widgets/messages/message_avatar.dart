// lib/widgets/messages/message_avatar.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../common/user_avatar.dart';

/// Avatar pour les messages avec ombre élégante
class MessageAvatar extends StatelessWidget {
  final User contact;
  final double radius;

  const MessageAvatar({
    super.key,
    required this.contact,
    this.radius = 18.0,
  });

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
      child: UserAvatar(
        photoUrl: contact.photo,
        name: contact.nom,
        radius: radius,
        showPresence: false,
        hasStory: false,
      ),
    );
  }
}

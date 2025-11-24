// lib/widgets/common/conversation_avatar.dart
import 'package:flutter/material.dart';
import '../../models/contact.dart';
import 'user_avatar.dart';

/// Avatar pour la liste des conversations avec support stories et présence
class ConversationAvatar extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onStoryTap;
  final double radius;

  const ConversationAvatar({
    super.key,
    required this.contact,
    this.onStoryTap,
    this.radius = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      photoUrl: contact.photo,
      name: contact.nom,
      radius: radius,
      presence: contact.presence,
      showPresence: true,
      hasStory: contact.story.isNotEmpty,
      onTap: contact.story.isNotEmpty ? onStoryTap : null,
    );
  }
}

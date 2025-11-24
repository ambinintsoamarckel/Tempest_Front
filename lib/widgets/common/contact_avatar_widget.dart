// lib/widgets/common/contact_avatar_widget.dart
import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../theme/app_theme.dart';
import 'user_avatar.dart';

/// Avatar avec nom affiché en dessous (pour grilles de contacts)
class ContactAvatarWidget extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final double radius;
  final bool showName;

  const ContactAvatarWidget({
    super.key,
    required this.contact,
    this.onTap,
    this.radius = 24.0,
    this.showName = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              photoUrl: contact.photo,
              name: contact.nom,
              radius: radius,
              presence: contact.presence,
              showPresence: true,
            ),
            if (showName) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: radius * 2.2,
                child: Text(
                  contact.nom,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimaryDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

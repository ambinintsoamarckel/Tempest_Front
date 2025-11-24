// lib/screens/direct/widgets/direct_app_bar.dart
import 'package:flutter/material.dart';
import 'package:mini_social_network/models/user.dart';
import 'package:mini_social_network/theme/app_theme.dart';
import 'package:mini_social_network/widgets/common/user_avatar.dart';

class DirectAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User contact;
  final VoidCallback onBack;

  const DirectAppBar({super.key, required this.contact, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: onBack,
      ),
      title: Row(
        children: [
          UserAvatar(
            photoUrl: contact.photo,
            name: contact.nom,
            radius: 20,
            showPresence: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  contact.nom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _presenceColor(contact.presence),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _presenceText(contact.presence),
                        style: TextStyle(
                          fontSize: 12,
                          color: _presenceColor(contact.presence),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ActionIcon(icon: Icons.videocam_outlined, onPressed: () {}),
        ActionIcon(icon: Icons.call_outlined, onPressed: () {}),
        ActionIcon(icon: Icons.more_vert, onPressed: () {}),
        const SizedBox(width: 8),
      ],
    );
  }

  Color _presenceColor(String p) => switch (p.toLowerCase()) {
        'actif' || 'en ligne' => AppTheme.secondaryColor,
        'absent' => Colors.orange,
        'ne pas déranger' => AppTheme.accentColor,
        _ => Colors.grey,
      };

  String _presenceText(String p) => switch (p.toLowerCase()) {
        'actif' || 'en ligne' => 'En ligne',
        'absent' => 'Absent',
        'ne pas déranger' => 'Occupé',
        _ => 'Hors ligne',
      };

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const ActionIcon({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 22),
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }
}

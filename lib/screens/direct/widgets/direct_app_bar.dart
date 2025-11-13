// lib/screens/direct/widgets/direct_app_bar.dart
import 'package:flutter/material.dart';
import 'package:mini_social_network/models/user.dart';
import 'package:mini_social_network/theme/app_theme.dart';

class DirectAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User contact;
  final VoidCallback onBack;

  const DirectAppBar({super.key, required this.contact, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: onBack),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            backgroundImage:
                contact.photo != null ? NetworkImage(contact.photo!) : null,
            child: contact.photo == null
                ? Text(contact.nom[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.nom,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: _presenceColor(contact.presence),
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(_presenceText(contact.presence),
                        style: TextStyle(
                            fontSize: 12,
                            color: _presenceColor(contact.presence))),
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

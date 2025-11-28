// lib/screens/group/widgets/group_app_bar.dart
import 'package:flutter/material.dart';
import 'package:mini_social_network/models/group_message.dart';
import 'package:mini_social_network/screens/group/group_settings.dart';
import 'package:mini_social_network/widgets/common/user_avatar.dart';
import 'package:mini_social_network/theme/app_theme.dart';

class GroupAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Group group;
  final VoidCallback onBack;
  final VoidCallback? onSettingsClose; // ✅ Nouveau callback

  const GroupAppBar({
    Key? key,
    required this.group,
    required this.onBack,
    this.onSettingsClose, // ✅ Optionnel
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: onBack,
      ),
      title: Row(
        children: [
          _buildGroupAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  group.nom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.membres.length} membre${group.membres.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ActionIcon(
          icon: Icons.videocam_outlined,
          onPressed: () {
            // TODO: Implémenter appel vidéo de groupe
          },
        ),
        ActionIcon(
          icon: Icons.call_outlined,
          onPressed: () {
            // TODO: Implémenter appel audio de groupe
          },
        ),
        ActionIcon(
          icon: Icons.settings,
          onPressed: () => _navigateToSettings(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGroupAvatar() {
    if (group.photo != null && group.photo!.isNotEmpty) {
      return UserAvatar(
        photoUrl: group.photo,
        name: group.nom,
        radius: 20,
        showPresence: false,
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.groups_rounded,
        color: AppTheme.primaryColor,
        size: 22,
      ),
    );
  }

  Future<void> _navigateToSettings(BuildContext context) async {
    print('🔧 [GroupAppBar] Navigation vers les paramètres du groupe');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupSettingsScreen(groupe: group),
      ),
    );

    // ✅ Appel du callback après retour de Settings
    print('🔄 [GroupAppBar] Retour des paramètres, déclenchement du reload');
    onSettingsClose?.call();
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const ActionIcon({
    Key? key,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

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

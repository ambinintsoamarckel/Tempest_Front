// lib/screens/group/widgets/group_chat_app_bar.dart
import 'package:flutter/material.dart';
import 'package:mini_social_network/models/group_message.dart';
import 'package:mini_social_network/screens/group/services/group_chat_controller.dart';
import 'group_app_bar.dart';

class GroupChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GroupChatController controller;

  const GroupChatAppBar({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        if (controller.isLoading || controller.currentGroup == null) {
          return AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Chargement...'),
          );
        }

        return GroupAppBar(
          group: controller.currentGroup!,
          onBack: () => Navigator.pop(context),
          // ✅ Callback pour reload après Settings
          onSettingsClose: () => _handleSettingsClose(),
        );
      },
    );
  }

  // ✅ Méthode appelée après fermeture de GroupSettings
  Future<void> _handleSettingsClose() async {
    print('🔄 [GroupChatAppBar] Settings fermé, reload silencieux du groupe');
    await controller.reloadSilently();
    print('✅ [GroupChatAppBar] Reload terminé');
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

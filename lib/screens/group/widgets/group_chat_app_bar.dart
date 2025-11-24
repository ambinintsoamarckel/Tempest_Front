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
    // Écoute les changements du controller pour le group
    if (controller.isLoading || controller.currentGroup == null) {
      return AppBar(
        title: const Text('Chargement...'),
      );
    }

    return GroupAppBar(
      group: controller.currentGroup!,
      onBack: () => Navigator.pop(context),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

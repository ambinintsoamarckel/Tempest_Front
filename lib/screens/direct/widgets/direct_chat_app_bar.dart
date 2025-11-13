// lib/screens/direct/widgets/direct_chat_app_bar.dart
import 'package:flutter/material.dart';
import 'package:mini_social_network/models/user.dart';
import 'direct_app_bar.dart';
import 'package:mini_social_network/services/discu_message_service.dart';

class DirectChatAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String contactId;

  const DirectChatAppBar({super.key, required this.contactId});

  @override
  State<DirectChatAppBar> createState() => _DirectChatAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DirectChatAppBarState extends State<DirectChatAppBar> {
  late Future<User> _contactFuture;

  @override
  void initState() {
    super.initState();
    _contactFuture = _loadContact();
  }

  Future<User> _loadContact() async {
    final service = MessageService();
    final msgs = await service.receiveMessagesFromUrl(widget.contactId);
    return msgs.isNotEmpty && msgs[0].expediteur.id == widget.contactId
        ? msgs[0].expediteur
        : msgs[0].destinataire;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _contactFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AppBar(title: const Text('...'));
        }
        return DirectAppBar(
          contact: snapshot.data!,
          onBack: () => Navigator.pop(context),
        );
      },
    );
  }
}

// lib/screens/direct/widgets/direct_chat_app_bar.dart
import 'package:flutter/material.dart';
import 'package:mini_social_network/models/user.dart';
import 'direct_app_bar.dart';
import 'package:mini_social_network/services/user_service.dart';

class DirectChatAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String contactId;

  const DirectChatAppBar({super.key, required this.contactId});

  @override
  State<DirectChatAppBar> createState() => _DirectChatAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DirectChatAppBarState extends State<DirectChatAppBar> {
  late Future<User> _contactFuture; // ✅ Enlève le ?

  @override
  void initState() {
    super.initState();
    _contactFuture = _loadContact();
  }

  Future<User> _loadContact() async {
    // ✅ Enlève le ?
    try {
      final userService = UserService();
      final contact = await userService.getContactById(widget.contactId);

      // ✅ Utilise ?? pour garantir un retour non-null
      return contact ??
          User(
            id: widget.contactId,
            nom: "Contact inconnu",
            email: "inconnu@example.com",
            photo: null,
          );
    } catch (e) {
      print('❌ Erreur chargement contact: $e');
      // Retourne un user par défaut au lieu de null
      return User(
        id: widget.contactId,
        nom: "Contact inconnu",
        email: "inconnu@example.com",
        photo: null,
      );
    }
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

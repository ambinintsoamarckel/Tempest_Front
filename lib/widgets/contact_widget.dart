import 'package:flutter/material.dart';
import '../models/contact.dart';

class ContactWidget extends StatelessWidget {
  final Contact contact;

  const ContactWidget({super.key, required this.contact});

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Créer une discussion avec'),
              onTap: () {
                Navigator.pop(context);
                // Logique pour créer une discussion
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Créer un groupe avec'),
              onTap: () {
                Navigator.pop(context);
                // Logique pour créer un groupe
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(contact.avatarUrl),
      ),
      title: Text(contact.name),
      onTap: () => _showOptions(context),
    );
  }
}

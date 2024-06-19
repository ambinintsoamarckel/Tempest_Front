import 'package:flutter/material.dart';
import '../models/contact.dart';

class ContactWidget extends StatelessWidget {
  final Contact contact;

  const ContactWidget({required this.contact, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(contact.avatarUrl),
      ),
      title: Text(contact.name),
      subtitle: Text(contact.phoneNumber),
      onTap: () {
        // Action à effectuer lors du clic sur un contact
      },
    );
  }
}

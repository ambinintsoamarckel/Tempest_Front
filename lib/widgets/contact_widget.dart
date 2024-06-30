import 'package:flutter/material.dart';
import '../models/contact.dart';

class ContactWidget extends StatelessWidget {
  final Contact contact;

  const ContactWidget({Key? key, required this.contact}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
                        backgroundImage: contact.avatarUrl != null
                            ? NetworkImage(contact.avatarUrl!)
                            : null,
                        child: contact.avatarUrl == null ? const Icon(Icons.person) : null,
                      ),
      title: Text(contact.name),
    );
  }
}

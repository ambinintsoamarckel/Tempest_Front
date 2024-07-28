import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../screens/all_screen.dart';

class ContactWidget extends StatelessWidget {
  final Contact contact;

  const ContactWidget({super.key, required this.contact});

  Widget _buildAvatar(Contact contact, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (contact.story.isNotEmpty) {
          _navigateToAllStoriesScreen(context, contact);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: contact.story.isNotEmpty
              ? Border.all(color: Colors.blue.shade900, width: 3)
              : null,
        ),
        child: CircleAvatar(
          radius: 24.0,
          backgroundImage: contact.photo != null
              ? NetworkImage(contact.photo!)
              : null,
          child: contact.photo == null
              ? const Icon(Icons.person, size: 24.0)
              : null,
        ),
      ),
    );
  }

  void _navigateToAllStoriesScreen(BuildContext context, Contact contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllStoriesScreen(
          storyIds: contact.story,
          initialIndex: 0,
        ),
      ),
    );
  }

  Widget _buildStatus(Contact user) {
    return user.presence != 'inactif'
        ? Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 25, 234, 42),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          _buildAvatar(contact, context),
          _buildStatus(contact),
        ],
      ),
      title: Text(contact.nom),
    );
  }
}

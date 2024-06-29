import 'package:flutter/material.dart';
import '../models/messages.dart';
import '../screens/direct_chat_screen.dart';
import '../screens/group_chat_screen.dart';

class ConversationWidget extends StatelessWidget {
  final Conversation conversation;

  const ConversationWidget({super.key, required this.conversation});

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archiver la conversation'),
              onTap: () {
                Navigator.pop(context);
                // Logique pour archiver la conversation
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Supprimer la conversation'),
              onTap: () {
                Navigator.pop(context);
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
        backgroundImage: conversation.contact.photo != null 
          ? NetworkImage(conversation.contact.photo!)
          : null,
        child: conversation.contact.photo == null ? const Icon(Icons.person) : null,
      ),
      title: Text(conversation.contact.nom),
      subtitle: Text(conversation.dernierMessage.contenu.texte),
      trailing: Text(
        conversation.dernierMessage.dateEnvoi.toLocal().toString(),
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: () {
        // Navigate to the correct chat screen based on conversation type
        /* if (conversation.contact.type == "groupe") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GroupChatScreen(conversation: conversation)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DirectChatScreen(conversation: conversation)),
          );
        } */
      },
      onLongPress: () => _showOptions(context),
    );
  }
}

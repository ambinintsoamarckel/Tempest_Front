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
                // Logique pour supprimer la conversation
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
      title: Text(conversation.name),
      subtitle: Text(conversation.lastMessage),
      trailing: Text(
        conversation.timestamp.toLocal().toString(),
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: () {
        // Navigate to the correct chat screen based on conversation type
        if (conversation.isGroup) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GroupChatScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DirectChatScreen()),
          );
        }
      },
      onLongPress: () => _showOptions(context),
    );
  }
}

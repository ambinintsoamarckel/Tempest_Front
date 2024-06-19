import 'package:flutter/material.dart';
import '../models/messages.dart';

class ConversationWidget extends StatelessWidget {
  final Conversation conversation;

  const ConversationWidget({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(conversation.name),
      subtitle: Text(conversation.lastMessage),
      trailing: Text(
        conversation.timestamp.toLocal().toString(),
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: () {
        // Navigate to the conversation details page
      },
    );
  }
}

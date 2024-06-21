import 'package:flutter/material.dart';
import '../models/messages.dart';
import '../widgets/messages_widget.dart';
import '../services/list_message_service.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final List<Conversation> _conversations = [];
  final MessageService _messageService = MessageService();

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      // Load conversations with contact or group
      // Example usage with a contact ID and a group ID, replace with your own logic
      List<Conversation> contactConversations = await _messageService.getConversationsWithContact('contactId');
      List<Conversation> groupConversations = await _messageService.getConversationsWithGroup('groupId');

      setState(() {
        _conversations.addAll(contactConversations);
        _conversations.addAll(groupConversations);
      });
    } catch (e) {
      print('Failed to load conversations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          return ConversationWidget(conversation: _conversations[index]);
        },
      ),
    );
  }
}

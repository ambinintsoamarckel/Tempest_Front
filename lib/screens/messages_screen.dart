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
  final ConversationService _conversationService = ConversationService(baseUrl: 'http://your_api_base_url_here');

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      List<Conversation> conversations = await _conversationService.getConversations();
      setState(() {
        _conversations.addAll(conversations);
      });
    } catch (e) {
      print('Failed to load conversations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          return ConversationWidget(conversation: _conversations[index]);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/messages.dart';
import '../services/list_message_service.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({Key? key}) : super(key: key);

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
      List<Conversation> contactConversations = await _messageService.getConversationsWithContact();
      setState(() {
        _conversations.addAll(contactConversations);
      });
    } catch (e) {
      print('Failed to load conversations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: _conversations.map((conversation) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: conversation.contact.photo != null
                            ? NetworkImage(conversation.contact.photo!)
                            : null,
                        child: conversation.contact.photo == null ? const Icon(Icons.person) : null,
                      ),
                      if (conversation.contact.presence == 'actif')
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_conversations[index].contact.nom),
            subtitle: Text(_conversations[index].dernierMessage.contenu.texte ?? ''),
            leading: CircleAvatar(
              backgroundImage: _conversations[index].contact.photo != null
                  ? NetworkImage(_conversations[index].contact.photo!)
                  : null,
              child: _conversations[index].contact.photo == null ? const Icon(Icons.person) : null,
            ),
            onTap: () {
              // Handle conversation tap
            },
          );
        },
      ),
    );
  }
}

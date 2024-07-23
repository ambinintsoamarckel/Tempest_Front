import 'package:flutter/material.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import '../models/messages.dart';
import '../services/list_message_service.dart';
import '../widgets/messages_widget.dart';
import '../main.dart';

class ConversationListScreen extends StatefulWidget {
  final GlobalKey<ConversationListScreenState> conversationListScreenKey;
  const ConversationListScreen({required this.conversationListScreenKey}) : super(key: conversationListScreenKey);

  @override
  ConversationListScreenState createState() => ConversationListScreenState();

  void reload() {
    final state = conversationListScreenKey.currentState;
    if (state != null) {
      state._reload();
    }
  }
}

class ConversationListScreenState extends State<ConversationListScreen> with RouteAware {
  final List<Conversation> _conversations = [];
  final MessageService _messageService = MessageService();
  final CurrentScreenManager screenManager = CurrentScreenManager();

  @override
  void initState() {
    super.initState();
    _loadConversations();
    screenManager.updateCurrentScreen('conversationList');
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

  Future<void> _reload() async {
    try {
      List<Conversation> contactConversations = await _messageService.getConversationsWithContact();
      setState(() {
        _conversations.clear();
        _conversations.addAll(contactConversations);
      });
    } catch (e) {
      print('Failed to load conversations: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    screenManager.updateCurrentScreen('conversationList');
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110.0),
        child: AppBar(
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: Row(
              children: _conversations.map((conversation) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24.0, // Taille de l'avatar
                            backgroundImage: conversation.contact.photo != null
                                ? NetworkImage(conversation.contact.photo!)
                                : null,
                            child: conversation.contact.photo == null
                                ? const Icon(Icons.person, size: 24.0)
                                : null,
                          ),
                          if (conversation.contact.presence == 'actif')
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4), // Espacement entre l'avatar et le nom
                      Flexible(
                        child: Text(
                          conversation.contact.nom,
                          style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)), // Taille de la police
                          overflow: TextOverflow.ellipsis, // Ajoutez l'overflow pour éviter le débordement
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          return ConversationWidget(conversation: _conversations[index]);
        },
      ),
    );
  }
}

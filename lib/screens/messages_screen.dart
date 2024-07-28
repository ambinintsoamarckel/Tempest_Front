import 'package:flutter/material.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import '../models/messages.dart';
import '../services/list_message_service.dart';
import '../widgets/messages_widget.dart';
import '../main.dart';
import  'all_screen.dart';

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


  Widget _buildAvatar(Contact contact, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (contact.story.isNotEmpty) {
          _navigateToAllStoriesScreen(context,contact);
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
      MaterialPageRoute(builder: (context) => AllStoriesScreen(storyIds: contact.story,initialIndex: 0,)),
    );
  }


Widget _buildStatus(Contact user) {
  // Vérifiez si user.story n'est pas vide
  if (user.presence!='inactif') {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.fromARGB(255, 25, 234, 42),
        ),
      ),
    );
  } else {
    // Si user.story est vide, retournez un widget vide
    return SizedBox.shrink();
  }
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _conversations.map((conversation) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Stack(
                          children: [
                            _buildAvatar(conversation.contact, context),
                            _buildStatus(conversation.contact),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            conversation.contact.nom,
                            style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
                            overflow: TextOverflow.ellipsis,
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

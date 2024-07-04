import 'package:flutter/material.dart';
import '../models/messages.dart';
import '../services/list_message_service.dart';
import '../widgets/messages_widget.dart';
import '../services/user_service.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({Key? key}) : super(key: key);

  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();
  late Future<List<Conversation>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _conversationsFuture = _loadConversations();
  }

  Future<List<Conversation>> _loadConversations() async {
    try {
      return await _messageService.getConversationsWithContact();
    } catch (e) {
      print('Failed to load conversations: $e');
      return [];
    }
  }

  void _logout(BuildContext context) async {
    await _userService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140.0), // Ajustez la hauteur selon vos besoins
        child: AppBar(
          backgroundColor: Colors.blueAccent,
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: FutureBuilder<List<Conversation>>(
                  future: _conversationsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Failed to load conversations'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No conversations found'));
                    } else {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: snapshot.data!.map((conversation) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5.0),
                              child: Column(
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
                                      style: TextStyle(fontSize: 14, color: Colors.white), // Taille de la police
                                      overflow: TextOverflow.ellipsis, // Ajoutez l'overflow pour éviter le débordement
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Conversation>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load conversations'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No conversations found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return ConversationWidget(conversation: snapshot.data![index]);
              },
            );
          }
        },
      ),
    );
  }
}

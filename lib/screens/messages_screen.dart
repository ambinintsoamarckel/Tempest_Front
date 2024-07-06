import 'package:flutter/material.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import '../models/messages.dart';
import '../services/list_message_service.dart';
import '../widgets/messages_widget.dart';
import '../services/user_service.dart';
import '../main.dart'; // Importez le fichier principal où le routeObserver est défini.
class ConversationListScreen extends StatefulWidget {

  static final GlobalKey<_ConversationListScreenState> conversationListScreenKey = GlobalKey<_ConversationListScreenState>();
  ConversationListScreen() : super(key: conversationListScreenKey);

  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();

  void reload() {
    final state = conversationListScreenKey.currentState;
    if (state != null) {
      state._loadConversations();
    }
  }
}

class _ConversationListScreenState extends State<ConversationListScreen> with RouteAware {
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();
  late Future<List<Conversation>> _conversationsFuture;
  final CurrentScreenManager screenManager = CurrentScreenManager();
  

  @override
  void initState() {
    super.initState();
    _loadConversations();
    screenManager.updateCurrentScreen('conversationList');
    print('initialisation messgescreen');
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
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _conversationsFuture = _messageService.getConversationsWithContact();
    });
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

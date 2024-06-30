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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140.0), // Ajustez la hauteur selon vos besoins
        child: AppBar(
          backgroundColor: Colors.blueAccent,
          actions: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _conversations.map((conversation) {
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
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              ListTile(
                title: Text(
                  _conversations[index].contact.nom,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _conversations[index].dernierMessage.contenu.texte ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: CircleAvatar(
                  radius: 28.0,
                  backgroundImage: _conversations[index].contact.photo != null
                      ? NetworkImage(_conversations[index].contact.photo!)
                      : null,
                  child: _conversations[index].contact.photo == null
                      ? const Icon(Icons.person, size: 28.0)
                      : null,
                ),
                trailing: Text(
                  '15:30', // Vous pouvez remplacer par l'heure du dernier message
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () {
                  // Handle conversation tap
                },
              ),
              Divider(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle add new conversation
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}

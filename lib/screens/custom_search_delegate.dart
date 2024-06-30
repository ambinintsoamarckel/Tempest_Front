import 'package:flutter/material.dart';
import '../models/messages.dart';
import '../services/list_message_service.dart';

class CustomSearchDelegate extends SearchDelegate {
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  final MessageService _messageService = MessageService();

  CustomSearchDelegate() {
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      _conversations = await _messageService.getConversationsWithContact();
    } catch (e) {
      // Handle any errors here
      print('Error loading conversations: $e');
    }

    // Mettez à jour l'état pour indiquer que le chargement est terminé
    _isLoading = false;
    // Forcer la reconstruction pour mettre à jour l'UI
    query = query;
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final results = _conversations.where((conversation) {
      return conversation.contact.nom.toLowerCase().contains(query.toLowerCase()) ||
             (conversation.dernierMessage.contenu.texte?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final conversation = results[index];
        return ListTile(
          title: Text(conversation.contact.nom),
          subtitle: Text(conversation.dernierMessage.contenu.texte ?? ''),
          onTap: () {
            // Action à effectuer lors de la sélection d'une conversation
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (query.isEmpty) {
      return const Center(child: Text('Commencez à taper pour rechercher'));
    }

    final suggestions = _conversations.where((conversation) {
      return conversation.contact.nom.toLowerCase().contains(query.toLowerCase()) ||
             (conversation.dernierMessage.contenu.texte?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final conversation = suggestions[index];
        return ListTile(
          title: Text(conversation.contact.nom),
          subtitle: Text(conversation.dernierMessage.contenu.texte ?? ''),
          onTap: () {
            // Action à effectuer lors de la sélection d'une suggestion
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/messages.dart';
import '../screens/direct_chat_screen.dart';
import '../screens/group_chat_screen.dart';

class ConversationWidget extends StatelessWidget {
  final Conversation conversation;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  ConversationWidget({Key? key, required this.conversation}) : super(key: key);

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archiver la conversation'),
              onTap: () {
                Navigator.pop(context);
                // Logique pour archiver la conversation
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Supprimer la conversation'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: secureStorage.read(key: 'user'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Ou n'importe quel autre indicateur de chargement
        } else if (snapshot.hasData) {
          final userId = snapshot.data!.replaceAll('"', '');
          final isMessageSentByUser = conversation.dernierMessage.expediteur == userId;
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: conversation.contact.photo != null
                  ? NetworkImage(conversation.contact.photo!)
                  : null,
              child: conversation.contact.photo == null ? const Icon(Icons.person) : null,
            ),
            title: Text(conversation.contact.nom),
            subtitle: isMessageSentByUser ? _buildSentMessage(userId) : _buildReceivedMessage(userId),
            trailing: Text(
              conversation.dernierMessage.dateEnvoi.toLocal().toString(),
              style: TextStyle(
                color: _isUnread(userId) ? Colors.blue : Colors.grey,
                fontSize: 12,
                fontWeight: _isUnread(userId) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () => _navigateToChatScreen(context),
            onLongPress: () => _showOptions(context),
          );
        } else {
          return const SizedBox(); // Placeholder or loading indicator
        }
      },
    );
  }

  Widget _buildSentMessage(String userId) {
    final message = conversation.dernierMessage;
    final content = _getContentSubtitle(message.contenu);
    final isRead = message is DernierMessageUtilisateur
        ? (message as DernierMessageUtilisateur).lu
        : (message as DernierMessageGroupe).luPar.any((lecture) => lecture.utilisateurId == userId);
    return Text(
      'Vous: $content',
      style: TextStyle(
        color: isRead ? Colors.grey : Colors.black,
        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
      ),
    );
  }

  Widget _buildReceivedMessage(String userId) {
    final message = conversation.dernierMessage;
    final content = _getContentSubtitle(message.contenu);
    final isRead = message is DernierMessageUtilisateur
        ? (message as DernierMessageUtilisateur).lu
        : (message as DernierMessageGroupe).luPar.any((lecture) => lecture.utilisateurId == userId);
    return Text(
      content,
      style: TextStyle(
        color: isRead ? Colors.grey : Colors.black,
        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
      ),
    );
  }

  String _getContentSubtitle(Contenu contenu) {
    switch (contenu.type) {
      case 'texte':
        return contenu.texte ?? '';
      case 'image':
        return 'a envoyé une photo';
      case 'audio':
        return 'a envoyé un audio';
      case 'video':
        return 'a envoyé une vidéo';
      default:
        return 'a envoyé une pièce jointe';
    }
  }

  void _navigateToChatScreen(BuildContext context) {
/*     if (conversation.contact.type == "groupe") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GroupChatScreen(conversation: conversation)),
      );
    } else if (conversation.contact.type == "utilisateur") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DirectChatScreen(conversation: conversation)),
      );
    } */
  }

  bool _isUnread(String userId) {
    if (conversation.dernierMessage is DernierMessageUtilisateur) {
      DernierMessageUtilisateur message = conversation.dernierMessage as DernierMessageUtilisateur;
      return message.expediteur != userId && !message.lu;
    } else if (conversation.dernierMessage is DernierMessageGroupe) {
      DernierMessageGroupe message = conversation.dernierMessage as DernierMessageGroupe;
      // Vérifie si l'utilisateur en session n'a pas lu ce message dans le groupe
      return message.expediteur != userId && !message.luPar.any((lecture) => lecture.utilisateurId == userId);
    }
    return false; // Par défaut, considéré comme lu si le type n'est pas reconnu
  }
}

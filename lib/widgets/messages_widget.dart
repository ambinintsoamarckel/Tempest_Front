import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // Pour la gestion des formats de date
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
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDate(conversation.dernierMessage.dateEnvoi),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                if (isMessageSentByUser) _buildReadStatus(userId),
              ],
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
    final content = _getContentSubtitle(message.contenu, true);
    return Text(
      content,
      style: TextStyle(
        color: const Color.fromARGB(255, 80, 79, 79),
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget _buildReceivedMessage(String userId) {
    final message = conversation.dernierMessage;
    final content = _getContentSubtitle(message.contenu, false);
    final isRead = message is DernierMessageUtilisateur
        ? (message as DernierMessageUtilisateur).lu
        : (message as DernierMessageGroupe).luPar.any((lecture) => lecture.utilisateurId == userId);
    return Text(
      content,
      style: TextStyle(
        color: isRead ? const Color.fromARGB(255, 80, 79, 79) : Colors.black,
        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
      ),
    );
  }

  String _getContentSubtitle(Contenu contenu, bool isSentByUser) {
    if (isSentByUser) {
      switch (contenu.type) {
        case 'texte':
          return 'Vous: ${contenu.texte ?? ''}';
        case 'image':
          return 'Vous avez envoyé une photo';
        case 'audio':
          return 'Vous avez envoyé un audio';
        case 'video':
          return 'Vous avez envoyé une vidéo';
        default:
          return 'Vous avez envoyé une pièce jointe';
      }
    } else {
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
  }

  void _navigateToChatScreen(BuildContext context) {
    if (conversation.contact.type == "groupe") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GroupChatScreen(groupId: conversation.contact.id)),
      );
    } else if (conversation.contact.type == "utilisateur") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DirectChatScreen(id: conversation.contact.id)),
      );
    }
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

  Widget _buildReadStatus(String userId) {
    if (conversation.dernierMessage is DernierMessageGroupe) {
      DernierMessageGroupe message = conversation.dernierMessage as DernierMessageGroupe;
      if (message.luPar.isNotEmpty) {
        return const Icon(Icons.done_all, color: Colors.blue);
      } else {
        return const Icon(Icons.done, color: Colors.grey);
      }
    } else if (conversation.dernierMessage is DernierMessageUtilisateur) {
      DernierMessageUtilisateur message = conversation.dernierMessage as DernierMessageUtilisateur;
      if (message.lu) {
        return const Icon(Icons.done_all, color: Colors.blue);
      } else {
        return const Icon(Icons.done, color: Colors.grey);
      }
    }
    return const SizedBox.shrink();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return DateFormat.Hm().format(date); // Heure si aujourd'hui
    } else if (difference.inDays == 1) {
      return 'Hier'; // Hier
    } else {
      return DateFormat('yyyy/MM/dd').format(date); // Date en format yyyy/MM/dd
    }
  }
}

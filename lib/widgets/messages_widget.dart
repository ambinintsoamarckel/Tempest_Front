import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // Pour la gestion des formats de date
import '../models/messages.dart';
import '../screens/direct_chat_screen.dart';
import '../screens/group_chat_screen.dart';
import '../screens/all_screen.dart';

class ConversationWidget extends StatelessWidget {
  final Conversation conversation;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  const ConversationWidget({super.key, required this.conversation});

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
    return FutureBuilder<String?>(
      future: secureStorage.read(key: 'user'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Ou n'importe quel autre indicateur de chargement
        } else if (snapshot.hasData) {
          final userId = snapshot.data!.replaceAll('"', '');
          final isMessageSentByUser = conversation.dernierMessage.expediteur == userId;
          return ListTile(
            leading:Stack(
                        children: [
                          _buildAvatar(conversation.contact,context),
                          
                          _buildStatus(conversation.contact),
                        ],
                      ),
            title: Text(conversation.contact.nom),
            subtitle: isMessageSentByUser ? _buildSentMessage(userId) : _buildReceivedMessage(userId),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDate(conversation.dernierMessage.dateEnvoi),
                  style: const TextStyle(
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
      style: const TextStyle(
        color: Color.fromARGB(255, 80, 79, 79),
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget _buildReceivedMessage(String userId) {
    final message = conversation.dernierMessage;
    final content = _getContentSubtitle(message.contenu, false);
    final isRead = message is DernierMessageUtilisateur
        ? (message).lu
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
    const int maxLength = 25; // Limite du nombre de caractères
    String text;

    if (isSentByUser) {
      switch (contenu.type) {
        case 'texte':
          text = 'Vous: ${contenu.texte ?? ''}';
          break;
        case 'image':
          text = 'Vous avez envoyé une photo';
          break;
        case 'audio':
          text = 'Vous avez envoyé un audio';
          break;
        case 'video':
          text = 'Vous avez envoyé une vidéo';
          break;
        default:
          text = 'Vous avez envoyé une pièce jointe';
      }
    } else {
      switch (contenu.type) {
        case 'texte':
          text = contenu.texte ?? '';
          break;
        case 'image':
          text = 'a envoyé une photo';
          break;
        case 'audio':
          text = 'a envoyé un audio';
          break;
        case 'video':
          text = 'a envoyé une vidéo';
          break;
        default:
          text = 'a envoyé une pièce jointe';
      }
    }

    if (text.length > maxLength) {
      text = '${text.substring(0, maxLength)}...';
    }

    return text;
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
    final DateTime adjustedDate = date;
    final now = DateTime.now();

    final nowDate = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(adjustedDate.year, adjustedDate.month, adjustedDate.day);

    final difference = nowDate.difference(messageDate).inDays;

    if (difference == 0) {
  final DateTime adjustedDat = date.add(const Duration(hours: 3)); // Ajouter 3 heures pour GMT+3
    return DateFormat.Hm().format(adjustedDat); 
    } else if (difference == 1) {
      return 'Hier';
    } else {
  return DateFormat('yyyy/MM/dd').format(messageDate); 
    
    }
  }
}

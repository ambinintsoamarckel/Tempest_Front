import 'package:flutter/material.dart';
import '../models/messages.dart';
import '../screens/direct_chat_screen.dart';
import '../screens/group_chat_screen.dart';

class ConversationWidget extends StatelessWidget {
  final Conversation conversation;

  const ConversationWidget({Key? key, required this.conversation}) : super(key: key);

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
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: conversation.contact.photo != null 
          ? NetworkImage(conversation.contact.photo!)
          : null,
        child: conversation.contact.photo == null ? const Icon(Icons.person) : null,
      ),
      title: Text(conversation.contact.nom),
      subtitle: _buildSubtitle(),
      trailing: Text(
        conversation.dernierMessage.dateEnvoi.toLocal().toString(),
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: () => _navigateToChatScreen(context),
      onLongPress: () => _showOptions(context),
    );
  }

Widget _buildSubtitle() {
    if (conversation.dernierMessage is DernierMessageUtilisateur) {
      DernierMessageUtilisateur message = conversation.dernierMessage as DernierMessageUtilisateur;
      return _buildContentSubtitle(message.contenu);
    } else if (conversation.dernierMessage is DernierMessageGroupe) {
      DernierMessageGroupe message = conversation.dernierMessage as DernierMessageGroupe;
      return _buildContentSubtitle(message.contenu);
    }
    return const Text('');
  }

  Widget _buildContentSubtitle(Contenu contenu) {
    switch (contenu.type) {
      case 'texte':
        return Text(contenu.texte ?? '');
      case 'image':
        return const Text('a envoyé une photo');
        // Vous pouvez ajouter ici la gestion d'affichage de l'image si nécessaire
      case 'audio':
        return const Text('a envoyé un audio');
        // Vous pouvez ajouter ici la gestion d'affichage de l'audio si nécessaire
      case 'video':
        return const Text('a envoyé une vidéo');
        // Vous pouvez ajouter ici la gestion d'affichage de la vidéo si nécessaire
      default:
        return const Text('a envoyé une pièce jointe');
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
}

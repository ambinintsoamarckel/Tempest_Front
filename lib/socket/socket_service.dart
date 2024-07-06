import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mini_social_network/models/direct_message.dart' as direct;
import 'package:mini_social_network/models/group_message.dart' as group;
import 'package:mini_social_network/screens/group_chat_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mini_social_network/screens/direct_chat_screen.dart';
import 'package:mini_social_network/screens/messages_screen.dart';
import 'notification_service.dart';
import '../services/current_screen_manager.dart'; // Importez le CurrentScreenManager

class SocketService {
  IO.Socket? socket;
  final storage = FlutterSecureStorage();

  void initializeSocket(id) {
    socket = IO.io('http://mahm.tempest.dov:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.on('connect', (_) {
      socket!.emit('user_connected', id);
    });

    socket!.on('message_envoye_personne', (data) async {
      String? user = await storage.read(key: 'user');
      direct.DirectMessage message = direct.DirectMessage.fromJson(data);

      if (user != null) {
        user = user.replaceAll('"', '');
        if (user.trim() == message.destinataire.id.trim()) {
          String notificationContent;
          switch (message.contenu.type) {
            case direct.MessageType.texte:
              notificationContent = message.contenu.texte ?? 'Vous avez reçu un nouveau message texte.';
              break;
            case direct.MessageType.image:
              notificationContent = 'Vous avez reçu une nouvelle image.';
              break;
            case direct.MessageType.fichier:
              notificationContent = 'Vous avez reçu un nouveau fichier.';
              break;
            case direct.MessageType.audio:
              notificationContent = 'Vous avez reçu un nouveau message audio.';
              break;
            case direct.MessageType.video:
              notificationContent = 'Vous avez reçu une nouvelle vidéo.';
              break;
            default:
              notificationContent = 'Vous avez reçu un nouveau message.';
          }

          await NotificationService().showNotification(
            0,
            'Nouveau message de ${message.expediteur.nom}',
            notificationContent,
          );
          // Vérifier l'écran actuel en utilisant CurrentScreenManager
          if (CurrentScreenManager.currentScreen == 'directChat') {
            final state = DirectChatScreen.directChatScreenKey.currentState;

            if (state != null) {
            if(state.widget.id==message.expediteur.id)
                {
                  state.widget.reload();    
                }
              
            }
          }
          if(CurrentScreenManager.currentScreen == 'conversationList')
          {
            final state = ConversationListScreen.conversationListScreenKey.currentState;
            if (state != null) {
              state.widget.reload();
              }
          }
      }
    }});

    socket!.on('message_lu_personne', (expediteur) async {
      String? user = await storage.read(key: 'user');
      if (user != null) {
        user = user.replaceAll('"', '');
        if (user.trim() == expediteur.toString().trim()) {
          print('Matched!');
        } else {
          print('Not matched');
        }
      } else {
        print('User is null');
      }
    });

    socket!.on('message_envoye_groupe', (data) async {
      print('Membres du groupe reçus: $data');

      String? user = await storage.read(key: 'user');
      group.GroupMessage message = group.GroupMessage.fromJson(data);
      if (user != null) {
        user = user.replaceAll('"', '').trim();
        bool isMember = message.isUserInGroup(user);

        if (isMember) {
          print('Utilisateur est membre du groupe');
          if(message.expediteur.id!=user)
          {
             String notificationContent;
          switch (message.contenu.type) {
            case group.MessageType.texte:
              notificationContent = message.contenu.texte ?? 'Vous avez reçu un nouveau message texte.';
              break;
            case group.MessageType.image:
              notificationContent = 'Vous avez reçu une nouvelle image.';
              break;
            case group.MessageType.fichier:
              notificationContent = 'Vous avez reçu un nouveau fichier.';
              break;
            case group.MessageType.audio:
              notificationContent = 'Vous avez reçu un nouveau message audio.';
              break;
            case group.MessageType.video:
              notificationContent = 'Vous avez reçu une nouvelle vidéo.';
              break;
            default:
              notificationContent = 'Vous avez reçu un nouveau message.';
          }

          await NotificationService().showNotification(
            0,
            'Nouveau message de ${message.expediteur.nom}',
            notificationContent,
          );
          // Vérifier l'écran actuel en utilisant CurrentScreenManager
          if (CurrentScreenManager.currentScreen == 'groupChat') {
            final state = GroupChatScreen.groupChatScreenKey.currentState;

            if (state != null) {
            if(state.widget.groupId==message.groupe.id)
                {
                  state.widget.reload();    
                }
              
            }
          }
          if(CurrentScreenManager.currentScreen == 'conversationList')
          {
            final state = ConversationListScreen.conversationListScreenKey.currentState;
            if (state != null) {
              state.widget.reload();
              }
          }
          }

        } else {
          print('Utilisateur n\'est pas membre du groupe');
        }
      } else {
        print('Utilisateur est null');
      }
    });

    socket!.on('message_lu_groupe', (groupMembers) async {
      print('Membres du groupe reçus: $groupMembers');

      String? user = await storage.read(key: 'user');
      if (user != null) {
        user = user.replaceAll('"', '').trim();
        bool isMember = groupMembers.contains(user);

        if (isMember) {
          print('Utilisateur est membre du groupe');
        } else {
          print('Utilisateur n\'est pas membre du groupe');
        }
      } else {
        print('Utilisateur est null');
      }
    });

    socket!.on('utilisateur_cree', (message) {
      print('eto ary $message');
    });

    socket!.on('utilisateur_modifie', (message) {
      print('eto ary $message');
    });

    socket!.on('utilisateur_supprime', (message) {
      print('eto ary $message');
    });

    socket!.on('story_ajoutee', (message) {
      print('eto ary $message');
    });

    socket!.on('photo_changee', (message) {
      print('eto ary $message');
    });

    socket!.on('groupe_quitte', (message) {
      print('eto ary $message');
    });

    socket!.on('groupe_cree', (message) {
      print('eto ary $message');
    });

    socket!.on('story_supprimee', (message) {
      print('eto ary $message');
    });

    socket!.on('story_vue', (viewers) async {
      String? user = await storage.read(key: 'user');
      if (user != null) {
        user = user.replaceAll('"', '');
        if (user.trim() == viewers.toString().trim()) {
          print('Matched!');
        } else {
          print('Not matched');
        }
      } else {
        print('User is null');
      }
    });

    socket!.on('groupe_supprime', (message) {
      print('eto ary $message');
    });

    socket!.on('photo_groupe_changee', (message) {
      print('eto ary $message');
    });

    socket!.on('membre_ajoute', (message) {
      print('eto ary $message');
    });

    socket!.on('membre_supprime', (message) {
      print('eto ary $message');
    });

    socket!.on('groupe_mis_a_jour', (message) {
      print('eto ary $message');
    });

    socket!.on('message_supprime', (message) {
      print('eto ary $message');
    });

    socket!.on('membre_supprime', (message) {
      print('eto ary $message');
    });

    socket!.on('disconnect', (_) {
      print('déconnecté');
      socket!.emit('user_disconnected', id);
    });

    socket!.on('message', (data) {
      print('message: $data');
    });
  }

  void sendMessage(String message) {
    socket!.emit('message', message);
  }

  void disconnect() {
    socket!.disconnect();
  }
}

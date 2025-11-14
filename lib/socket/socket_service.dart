import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mini_social_network/models/direct_message.dart' as direct;
import 'package:mini_social_network/models/group_message.dart' as group;
import 'package:mini_social_network/screens/group_chat_screen.dart';
import 'package:mini_social_network/screens/home_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mini_social_network/screens/direct/direct_chat_screen.dart';
import 'notification_service.dart';
import '../services/current_screen_manager.dart'; // Importez le CurrentScreenManager

class SocketService {
  IO.Socket? socket;
  final storage = const FlutterSecureStorage();

  void initializeSocket(id) {
    socket = IO.io(dotenv.env['SOCKET_URL']!, <String, dynamic>{
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
              notificationContent = message.contenu.texte ??
                  'Vous avez reçu un nouveau message texte.';
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
            'direct|${message.expediteur.id}', // Payload format: 'type|id'
          );

          // Vérifier l'écran actuel en utilisant CurrentScreenManager
          if (CurrentScreenManager.currentScreen == 'directChat') {
            final state = DirectChatScreen.directChatScreenKey.currentState;

            if (state != null) {
              if (state.widget.contactId == message.expediteur.id) {
                state.widget.reloadFromSocket();
              }
            }
          }
          if (CurrentScreenManager.currentScreen == 'conversationList') {
            final state = HomeScreenState.conversationListScreen.currentState;
            if (state != null) {
              state.widget.reload();
            }
          }
        }
      }
    });

    socket!.on('message_lu_personne', (data) async {
      String? user = await storage.read(key: 'user');
      if (user != null) {
        user = user.replaceAll('"', '');
        print(data);
        if (user.trim() == data['expediteur'].toString().trim()) {
          print('Matched!');
          if (CurrentScreenManager.currentScreen == 'directChat') {
            final state = DirectChatScreen.directChatScreenKey.currentState;

            if (state != null) {
              if (state.widget.contactId == data['destinataire']) {
                 print('Socket reloaded avant direct chat screen');
                state.widget.reloadFromSocket();

              }
            }
          }
          if (CurrentScreenManager.currentScreen == 'conversationList') {
            final state = HomeScreenState.conversationListScreen.currentState;
            if (state != null) {
              state.widget.reload();
            }
          }
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
          if (message.expediteur.id != user) {
            String notificationContent;
            switch (message.contenu.type) {
              case group.MessageType.texte:
                notificationContent = message.contenu.texte ??
                    'Vous avez reçu un nouveau message texte.';
                break;
              case group.MessageType.image:
                notificationContent = 'Vous avez reçu une nouvelle image.';
                break;
              case group.MessageType.fichier:
                notificationContent = 'Vous avez reçu un nouveau fichier.';
                break;
              case group.MessageType.audio:
                notificationContent =
                    'Vous avez reçu un nouveau message audio.';
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
              'group|${message.groupe.id}', // Payload format: 'type|id'
            );
            // Vérifier l'écran actuel en utilisant CurrentScreenManager
            if (CurrentScreenManager.currentScreen == 'groupChat') {
              final state = GroupChatScreen.groupChatScreenKey.currentState;

              if (state != null) {
                if (state.widget.groupId == message.groupe.id) {
                  state.widget.reload();
                }
              }
            }
            if (CurrentScreenManager.currentScreen == 'conversationList') {
              final state = HomeScreenState.conversationListScreen.currentState;
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

    socket!.on('message_lu_groupe', (data) async {
      print('Membres du groupe reçus: $data');

      String? user = await storage.read(key: 'user');
      if (user != null) {
        user = user.replaceAll('"', '').trim();
        bool isMember = data['membres'].contains(user);

        if (isMember) {
          if (data['vu'] != user) {
            if (CurrentScreenManager.currentScreen == 'groupChat') {
              final state = GroupChatScreen.groupChatScreenKey.currentState;

              if (state != null) {
                if (state.widget.groupId == data['groupe']) {
                  state.widget.reload();
                }
              }
            }
            if (CurrentScreenManager.currentScreen == 'conversationList') {
              final state = HomeScreenState.conversationListScreen.currentState;
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

    socket!.on('utilisateur_cree', (message) {
      if (CurrentScreenManager.currentScreen == 'contact') {
        final state = HomeScreenState.contactScreenState.currentState;
        if (state != null) {
          state.widget.reload();
        }
      }
      if (CurrentScreenManager.currentScreen == 'conversationList') {
        final state = HomeScreenState.conversationListScreen.currentState;
        if (state != null) {
          state.widget.reload();
        }
      }
    });

    socket!.on('utilisateur_modifie', (message) {
      if (CurrentScreenManager.currentScreen == 'contact') {
        final state = HomeScreenState.contactScreenState.currentState;
        if (state != null) {
          state.widget.reload();
        }
      }
      if (CurrentScreenManager.currentScreen == 'conversationList') {
        final state = HomeScreenState.conversationListScreen.currentState;
        if (state != null) {
          state.widget.reload();
        }
      }
    });

    socket!.on('utilisateur_supprime', (message) {
      if (CurrentScreenManager.currentScreen == 'contact') {
        final state = HomeScreenState.contactScreenState.currentState;
        if (state != null) {
          state.widget.reload();
        }
      }
      if (CurrentScreenManager.currentScreen == 'conversationList') {
        final state = HomeScreenState.conversationListScreen.currentState;
        if (state != null) {
          state.widget.reload();
        }
      }
    });

    socket!.on('story_ajoutee', (message) {
      if (CurrentScreenManager.currentScreen == 'story') {
        final state = HomeScreenState.storyScreenKey.currentState;
        if (state != null) {
          state.widget.reload();
        }
      }
    });
    socket!.on('story_expire', (message) {
      print('storyyyyyyiiization');
      if (CurrentScreenManager.currentScreen == 'story') {
        final state = HomeScreenState.storyScreenKey.currentState;
        if (state != null) {
          state.widget.reload();
        }
      }
    });
    socket!.on('photo_changee', (message) {
      if (CurrentScreenManager.currentScreen == 'contact') {
        final state = HomeScreenState.contactScreenState.currentState;
        if (state != null) {
          state.widget.reload();
        }
      }
      if (CurrentScreenManager.currentScreen == 'conversationList') {
        final state = HomeScreenState.conversationListScreen.currentState;
        if (state != null) {
          state.widget.reload();
        }
      }
    });

    socket!.on('story_supprimee', (message) {
      if (CurrentScreenManager.currentScreen == 'story') {
        final state = HomeScreenState.storyScreenKey.currentState;
        if (state != null) {
          state.widget.reload();
        }
      }
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

/*     socket!.on('groupe_supprime', (message) {
     if (CurrentScreenManager.currentScreen == 'contact') {
        final state = HomeScreenState.contactScreenState.currentState;
        if (state != null) {
        state.widget.reload();
        }
      }
    if(CurrentScreenManager.currentScreen == 'conversationList')
    {

      final state = HomeScreenState.conversationListScreen.currentState;
      if (state != null) {
        state.widget.reload();
        }
    }
    }); */

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

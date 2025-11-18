// socket_service.dart - REMPLACEZ votre fichier par celui-ci

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mini_social_network/models/direct_message.dart' as direct;
import 'package:mini_social_network/models/group_message.dart' as group;
import 'package:mini_social_network/screens/group_chat_screen.dart';
import 'package:mini_social_network/screens/home_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mini_social_network/screens/direct/direct_chat_screen.dart';
import 'notification_service.dart';
import '../services/current_screen_manager.dart';

class SocketService {
  IO.Socket? socket;
  final storage = const FlutterSecureStorage();
  String? _currentUserId; // ✅ Cache l'ID utilisateur

  void initializeSocket(id) async {
    // ✅ Charge l'ID utilisateur UNE SEULE FOIS au démarrage
    _currentUserId = await storage.read(key: 'user');
    if (_currentUserId != null) {
      _currentUserId = _currentUserId!.replaceAll('"', '').trim();
      print('👤 [SocketService] Current user ID: $_currentUserId');
    } else {
      print('⚠️ [SocketService] Pas d\'ID utilisateur trouvé dans storage');
    }

    socket = IO.io(dotenv.env['SOCKET_URL']!, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.on('connect', (_) {
      print('✅ Socket connecté');
      socket!.emit('user_connected', id);
    });

    // ✅ CORRECTION CRITIQUE : Message lu par une personne
    socket!.on('message_lu_personne', (data) async {
      try {
        print('📖 [SocketService] message_lu_personne reçu');
        print('   📦 Data brut: $data');
        print('   👤 Current user: $_currentUserId');

        // ✅ Vérification si vous êtes l'expéditeur
        final expediteur = data['expediteur'].toString().trim();
        final destinataire = data['destinataire'].toString().trim();

        print('   📤 Expéditeur du message: $expediteur');
        print('   📥 Destinataire du message: $destinataire');

        if (_currentUserId == null) {
          print(
              '❌ [SocketService] _currentUserId est null, impossible de comparer');
          return;
        }

        if (_currentUserId == expediteur) {
          print(
              '✅ [SocketService] VOUS ÊTES L\'EXPÉDITEUR - Reload nécessaire!');
          print('   🎯 Destinataire: $destinataire');
          print('   📍 Current screen: ${CurrentScreenManager.currentScreen}');

          // ✅ Reload direct chat si ouvert avec ce destinataire
          if (CurrentScreenManager.currentScreen == 'directChat') {
            print('🔄 [SocketService] Tentative reload direct chat...');
            _reloadDirectChat(destinataire);
          } else {
            print(
                '⚠️ [SocketService] Pas sur directChat (${CurrentScreenManager.currentScreen}), pas de reload');
          }

          // ✅ Reload conversation list
          if (CurrentScreenManager.currentScreen == 'conversationList') {
            print('🔄 [SocketService] Reload conversation list');
            _reloadConversationList();
          }
        } else {
          print('⚠️ [SocketService] Vous n\'êtes PAS l\'expéditeur');
          print('   Expéditeur attendu: $_currentUserId');
          print('   Expéditeur reçu: $expediteur');
        }
      } catch (e, stack) {
        print('❌ [SocketService] Erreur message_lu_personne: $e');
        print('   Stack: $stack');
      }
    });

    // ✅ Message envoyé à une personne
    socket!.on('message_envoye_personne', (data) async {
      try {
        print('📩 [SocketService] message_envoye_personne reçu');
        direct.DirectMessage message = direct.DirectMessage.fromJson(data);

        if (_currentUserId != null &&
            _currentUserId == message.destinataire.id.trim()) {
          print('📩 Message reçu de ${message.expediteur.nom}');

          // Notification
          String notificationContent =
              _getNotificationContent(message.contenu.type);
          await NotificationService().showNotification(
            0,
            'Nouveau message de ${message.expediteur.nom}',
            notificationContent,
            'direct|${message.expediteur.id}',
          );

          // ✅ Reload direct chat si ouvert avec ce contact
          if (CurrentScreenManager.currentScreen == 'directChat') {
            _reloadDirectChat(message.expediteur.id);
          }

          // ✅ Reload conversation list
          if (CurrentScreenManager.currentScreen == 'conversationList') {
            _reloadConversationList();
          }
        }
      } catch (e) {
        print('❌ [SocketService] Erreur message_envoye_personne: $e');
      }
    });

    // Messages groupe (gardez votre code existant)
    socket!.on('message_envoye_groupe', (data) async {
      try {
        group.GroupMessage message = group.GroupMessage.fromJson(data);

        if (_currentUserId != null) {
          bool isMember = message.isUserInGroup(_currentUserId!);

          if (isMember && message.expediteur.id != _currentUserId) {
            String notificationContent =
                _getGroupNotificationContent(message.contenu.type);

            await NotificationService().showNotification(
              0,
              'Nouveau message de ${message.expediteur.nom}',
              notificationContent,
              'group|${message.groupe.id}',
            );

            if (CurrentScreenManager.currentScreen == 'groupChat') {
              final state = GroupChatScreen.groupChatScreenKey.currentState;
              if (state != null && state.widget.groupId == message.groupe.id) {
                state.widget.reload();
              }
            }

            if (CurrentScreenManager.currentScreen == 'conversationList') {
              _reloadConversationList();
            }
          }
        }
      } catch (e) {
        print('❌ Erreur message_envoye_groupe: $e');
      }
    });

    socket!.on('message_lu_groupe', (data) async {
      try {
        if (_currentUserId != null) {
          bool isMember = data['membres'].contains(_currentUserId);

          if (isMember && data['vu'] != _currentUserId) {
            if (CurrentScreenManager.currentScreen == 'groupChat') {
              final state = GroupChatScreen.groupChatScreenKey.currentState;
              if (state != null && state.widget.groupId == data['groupe']) {
                state.widget.reload();
              }
            }

            if (CurrentScreenManager.currentScreen == 'conversationList') {
              _reloadConversationList();
            }
          }
        }
      } catch (e) {
        print('❌ Erreur message_lu_groupe: $e');
      }
    });

    // ✅ Autres événements (gardez votre code existant)
    _setupOtherListeners();

    socket!.on('disconnect', (_) {
      print('🔌 Socket déconnecté');
      socket!.emit('user_disconnected', id);
    });

    socket!.on('message', (data) {
      print('message: $data');
    });
  }

  // ✅ Helper pour reload direct chat
  void _reloadDirectChat(String contactId) {
    print(
        '🔍 [SocketService] Tentative reload direct chat avec contactId: $contactId');

    final state = DirectChatScreen.directChatScreenKey.currentState;

    if (state == null) {
      print('❌ [SocketService] directChatScreenKey.currentState est NULL');
      return;
    }

    print(
        '✅ [SocketService] State trouvé, contactId du widget: ${state.widget.contactId}');

    if (state.widget.contactId == contactId) {
      print('✅ [SocketService] ContactId correspond! Appel reloadFromSocket()');
      state.widget.reloadFromSocket();
    } else {
      print(
          '⚠️ [SocketService] ContactId ne correspond pas: ${state.widget.contactId} != $contactId');
    }
  }

  // ✅ Helper pour reload conversation list
  void _reloadConversationList() {
    final state = HomeScreenState.conversationListScreen.currentState;
    if (state != null) {
      print('🔄 Reload conversation list');
      state.widget.reload();
    }
  }

  // ✅ Helper pour notifications direct
  String _getNotificationContent(direct.MessageType type) {
    switch (type) {
      case direct.MessageType.texte:
        return 'Nouveau message texte';
      case direct.MessageType.image:
        return 'Nouvelle image';
      case direct.MessageType.fichier:
        return 'Nouveau fichier';
      case direct.MessageType.audio:
        return 'Nouveau message audio';
      case direct.MessageType.video:
        return 'Nouvelle vidéo';
      default:
        return 'Nouveau message';
    }
  }

  // ✅ Helper pour notifications groupe
  String _getGroupNotificationContent(group.MessageType type) {
    switch (type) {
      case group.MessageType.texte:
        return 'Nouveau message texte';
      case group.MessageType.image:
        return 'Nouvelle image';
      case group.MessageType.fichier:
        return 'Nouveau fichier';
      case group.MessageType.audio:
        return 'Nouveau message audio';
      case group.MessageType.video:
        return 'Nouvelle vidéo';
      default:
        return 'Nouveau message';
    }
  }

  void _setupOtherListeners() {
    socket!.on('utilisateur_cree', (message) {
      if (CurrentScreenManager.currentScreen == 'contact') {
        final state = HomeScreenState.contactScreenState.currentState;
        state?.widget.reload();
      }
      if (CurrentScreenManager.currentScreen == 'conversationList') {
        _reloadConversationList();
      }
    });

    socket!.on('utilisateur_modifie', (message) {
      if (CurrentScreenManager.currentScreen == 'contact') {
        final state = HomeScreenState.contactScreenState.currentState;
        state?.widget.reload();
      }
      if (CurrentScreenManager.currentScreen == 'conversationList') {
        _reloadConversationList();
      }
    });

    socket!.on('utilisateur_supprime', (message) {
      if (CurrentScreenManager.currentScreen == 'contact') {
        final state = HomeScreenState.contactScreenState.currentState;
        state?.widget.reload();
      }
      if (CurrentScreenManager.currentScreen == 'conversationList') {
        _reloadConversationList();
      }
    });

    socket!.on('story_ajoutee', (message) {
      if (CurrentScreenManager.currentScreen == 'story') {
        final state = HomeScreenState.storyScreenKey.currentState;
        state?.widget.reload();
      }
    });

    socket!.on('story_expire', (message) {
      if (CurrentScreenManager.currentScreen == 'story') {
        final state = HomeScreenState.storyScreenKey.currentState;
        state?.widget.reload();
      }
    });

    socket!.on('photo_changee', (message) {
      if (CurrentScreenManager.currentScreen == 'contact') {
        final state = HomeScreenState.contactScreenState.currentState;
        state?.widget.reload();
      }
      if (CurrentScreenManager.currentScreen == 'conversationList') {
        _reloadConversationList();
      }
    });

    socket!.on('story_supprimee', (message) {
      if (CurrentScreenManager.currentScreen == 'story') {
        final state = HomeScreenState.storyScreenKey.currentState;
        state?.widget.reload();
      }
    });

    socket!.on('story_vue', (viewers) async {
      if (_currentUserId != null) {
        if (_currentUserId == viewers.toString().trim()) {
          print('Matched!');
        } else {
          print('Not matched');
        }
      }
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
  }

  void sendMessage(String message) {
    socket!.emit('message', message);
  }

  void disconnect() {
    socket?.disconnect();
  }
}

// socket_service.dart - Version complète avec ScreenManager

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mini_social_network/models/direct_message.dart' as direct;
import 'package:mini_social_network/models/group_message.dart' as group;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'notification_service.dart';
import '../utils/screen_manager.dart';
import 'package:mini_social_network/models/message_content.dart';

class SocketService {
  IO.Socket? socket;
  final ScreenManager _screenManager = ScreenManager();
  final storage = const FlutterSecureStorage();
  String? _currentUserId;

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

    // ✅ Message lu par une personne
    socket!.on('message_lu_personne', (data) async {
      try {
        print('📖 [SocketService] message_lu_personne reçu');
        print('   📦 Data brut: $data');
        print('   👤 Current user: $_currentUserId');

        final expediteur = data['expediteur'].toString().trim();
        final destinataire = data['destinataire'].toString().trim();

        print('   📤 Expéditeur du message: $expediteur');
        print('   📥 Destinataire du message: $destinataire');

        if (_currentUserId == null) {
          print('❌ [SocketService] _currentUserId est null');
          return;
        }

        if (_currentUserId == expediteur) {
          print('✅ [SocketService] VOUS ÊTES L\'EXPÉDITEUR - Reload!');
          print('   🎯 Destinataire: $destinataire');
          print('   📍 Current screen: ${CurrentScreenManager.currentScreen}');

          // ✅ Reload direct chat si ouvert avec ce destinataire
          if (CurrentScreenManager.isOnScreen('directChat')) {
            print('🔄 [SocketService] Tentative reload direct chat...');
            _screenManager.reloadDirectChat(destinataire);
          }

          // ✅ Reload conversation list
          if (CurrentScreenManager.isOnScreen('conversationList')) {
            print('🔄 [SocketService] Reload conversation list');
            _screenManager.reloadConversationList();
          }
        } else {
          print('⚠️ [SocketService] Vous n\'êtes PAS l\'expéditeur');
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
          if (CurrentScreenManager.isOnScreen('directChat')) {
            _screenManager.reloadDirectChat(message.expediteur.id);
          }

          // ✅ Reload conversation list
          if (CurrentScreenManager.isOnScreen('conversationList')) {
            _screenManager.reloadConversationList();
          }
        }
      } catch (e) {
        print('❌ [SocketService] Erreur message_envoye_personne: $e');
      }
    });

    // ✅ Message envoyé à un groupe
    socket!.on('message_envoye_groupe', (data) async {
      try {
        group.GroupMessage message = group.GroupMessage.fromJson(data);

        if (_currentUserId != null) {
          bool isMember = message.isUserInGroup(_currentUserId!);

          if (isMember && message.expediteur.id != _currentUserId) {
            String notificationContent =
                _getNotificationContent(message.contenu.type);

            await NotificationService().showNotification(
              0,
              'Nouveau message de ${message.expediteur.nom}',
              notificationContent,
              'group|${message.groupe.id}',
            );

            // ✅ Reload group chat si ouvert avec ce groupe
            if (CurrentScreenManager.isOnScreen('groupChat')) {
              _screenManager.reloadGroupChat(message.groupe.id);
            }

            // ✅ Reload conversation list
            if (CurrentScreenManager.isOnScreen('conversationList')) {
              _screenManager.reloadConversationList();
            }
          }
        }
      } catch (e) {
        print('❌ Erreur message_envoye_groupe: $e');
      }
    });

    // ✅ Message lu dans un groupe
    socket!.on('message_lu_groupe', (data) async {
      try {
        if (_currentUserId != null) {
          bool isMember = data['membres'].contains(_currentUserId);

          if (isMember && data['vu'] != _currentUserId) {
            // ✅ Reload group chat si ouvert avec ce groupe
            if (CurrentScreenManager.isOnScreen('groupChat')) {
              _screenManager.reloadGroupChat(data['groupe']);
            }

            // ✅ Reload conversation list
            if (CurrentScreenManager.isOnScreen('conversationList')) {
              _screenManager.reloadConversationList();
            }
          }
        }
      } catch (e) {
        print('❌ Erreur message_lu_groupe: $e');
      }
    });

    // ✅ Autres événements
    _setupOtherListeners();

    socket!.on('disconnect', (_) {
      print('🔌 Socket déconnecté');
      socket!.emit('user_disconnected', id);
    });

    socket!.on('message', (data) {
      print('message: $data');
    });
  }

  // ✅ Une seule fonction pour les deux types de messages
  String _getNotificationContent(MessageType type) {
    switch (type) {
      case MessageType.texte:
        return 'Nouveau message texte';
      case MessageType.image:
        return 'Nouvelle image';
      case MessageType.fichier:
        return 'Nouveau fichier';
      case MessageType.audio:
        return 'Nouveau message audio';
      case MessageType.video:
        return 'Nouvelle vidéo';
    }
  }

  void _setupOtherListeners() {
    // ✅ Utilisateur créé
    socket!.on('utilisateur_cree', (message) {
      if (CurrentScreenManager.isOnScreen('contact')) {
        _screenManager.reloadContactScreen();
      }
      if (CurrentScreenManager.isOnScreen('conversationList')) {
        _screenManager.reloadConversationList();
      }
    });

    // ✅ Utilisateur modifié
    socket!.on('utilisateur_modifie', (message) {
      if (CurrentScreenManager.isOnScreen('contact')) {
        _screenManager.reloadContactScreen();
      }
      if (CurrentScreenManager.isOnScreen('conversationList')) {
        _screenManager.reloadConversationList();
      }
    });

    // ✅ Utilisateur supprimé
    socket!.on('utilisateur_supprime', (message) {
      if (CurrentScreenManager.isOnScreen('contact')) {
        _screenManager.reloadContactScreen();
      }
      if (CurrentScreenManager.isOnScreen('conversationList')) {
        _screenManager.reloadConversationList();
      }
    });

    // ✅ Story ajoutée
    socket!.on('story_ajoutee', (message) {
      if (CurrentScreenManager.isOnScreen('story')) {
        _screenManager.reloadStoryScreen();
      }
    });

    // ✅ Story expirée
    socket!.on('story_expire', (message) {
      if (CurrentScreenManager.isOnScreen('story')) {
        _screenManager.reloadStoryScreen();
      }
    });

    // ✅ Photo changée
    socket!.on('photo_changee', (message) {
      if (CurrentScreenManager.isOnScreen('contact')) {
        _screenManager.reloadContactScreen();
      }
      if (CurrentScreenManager.isOnScreen('conversationList')) {
        _screenManager.reloadConversationList();
      }
    });

    // ✅ Story supprimée
    socket!.on('story_supprimee', (message) {
      if (CurrentScreenManager.isOnScreen('story')) {
        _screenManager.reloadStoryScreen();
      }
    });

    // ✅ Story vue
    socket!.on('story_vue', (viewers) async {
      if (_currentUserId != null) {
        if (_currentUserId == viewers.toString().trim()) {
          print('Matched!');
        } else {
          print('Not matched');
        }
      }
    });

    // ✅ Membre ajouté au groupe
    socket!.on('membre_ajoute', (message) {
      print('Membre ajouté: $message');
      if (CurrentScreenManager.isOnScreen('conversationList')) {
        _screenManager.reloadConversationList();
      }
    });

    // ✅ Membre supprimé du groupe
    socket!.on('membre_supprime', (message) {
      print('Membre supprimé: $message');
      if (CurrentScreenManager.isOnScreen('conversationList')) {
        _screenManager.reloadConversationList();
      }
    });

    // ✅ Groupe mis à jour
    socket!.on('groupe_mis_a_jour', (message) {
      print('Groupe mis à jour: $message');
      if (CurrentScreenManager.isOnScreen('conversationList')) {
        _screenManager.reloadConversationList();
      }
      if (CurrentScreenManager.isOnScreen('groupChat')) {
        // Reload le chat du groupe si c'est celui-ci
        if (message['id'] != null) {
          _screenManager.reloadGroupChat(message['id']);
        }
      }
    });

    // ✅ Message supprimé
    socket!.on('message_supprime', (message) {
      print('Message supprimé: $message');
      if (CurrentScreenManager.isOnScreen('directChat')) {
        // Reload le chat direct
        if (message['contact_id'] != null) {
          _screenManager.reloadDirectChat(message['contact_id']);
        }
      }
      if (CurrentScreenManager.isOnScreen('groupChat')) {
        // Reload le chat du groupe
        if (message['group_id'] != null) {
          _screenManager.reloadGroupChat(message['group_id']);
        }
      }
    });
  }

  void sendMessage(String message) {
    socket!.emit('message', message);
  }

  void disconnect() {
    socket?.disconnect();
  }
}

import 'package:mini_social_network/models/user.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/direct_message.dart';
import 'notification_service.dart';



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
      // Handle user connected
      socket!.emit('user_connected', id);
    });
socket!.on('message_envoye_personne', (data) async {
      String? user = await storage.read(key: 'user');
      DirectMessage message = DirectMessage.fromJson(data);

      if (user != null) {
        // Enlever les guillemets supplémentaires
        user = user.replaceAll('"', '');
        if (user.trim() == message.destinataire.id.trim()) {
          // Afficher la notification en fonction du type de message
          String notificationContent;
          switch (message.contenu.type) {
            case MessageType.texte:
              notificationContent = message.contenu.texte ?? 'Vous avez reçu un nouveau message texte.';
              break;
            case MessageType.image:
              notificationContent = 'Vous avez reçu une nouvelle image.';
              break;
            case MessageType.fichier:
              notificationContent = 'Vous avez reçu un nouveau fichier.';
              break;
            case MessageType.audio:
              notificationContent = 'Vous avez reçu un nouveau message audio.';
              break;
            case MessageType.video:
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
        }
      }
    });

    socket!.on('message_lu_personne', (expediteur) async {
      String? user = await storage.read(key: 'user');
      if (user != null) {
        // Enlever les guillemets supplémentaires
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


    socket!.on('message_envoye_groupe', (groupMembers) async {
      print('Membres du groupe reçus: $groupMembers');

      String? user = await storage.read(key: 'user');
      if (user != null) {
        // Supprimer les guillemets supplémentaires si nécessaire
        user = user.replaceAll('"', '').trim();
        bool isMember = groupMembers.contains(user);

        if (isMember) {
          print('Utilisateur est membre du groupe');
          // Effectuer l'action spécifique si l'utilisateur est membre du groupe
        } else {
          print('Utilisateur n\'est pas membre du groupe');
          // Effectuer une autre action si nécessaire
        }
      } else {
        print('Utilisateur est null');
      }
    });

    socket!.on('message_lu_groupe', (groupMembers) async {
      print('Membres du groupe reçus: $groupMembers');

      String? user = await storage.read(key: 'user');
      if (user != null) {
        // Supprimer les guillemets supplémentaires si nécessaire
        user = user.replaceAll('"', '').trim();
        bool isMember = groupMembers.contains(user);

        if (isMember) {
          print('Utilisateur est membre du groupe');
          // Effectuer l'action spécifique si l'utilisateur est membre du groupe
        } else {
          print('Utilisateur n\'est pas membre du groupe');
          // Effectuer une autre action si nécessaire
        }
      } else {
        print('Utilisateur est null');
      }
    });



        socket!.on('utilisateur_cree', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('utilisateur_modifie', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('utilisateur_supprime', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('story_ajoutee', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('photo_changee', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('groupe_quitte', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('groupe_cree', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('story_supprimee', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
    
      socket!.on('story_vue', (viewers) async {

      String? user = await storage.read(key: 'user');
      if (user != null) {
        // Enlever les guillemets supplémentaires
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
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('photo_groupe_changee', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('membre_ajoute', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('membre_supprime', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('groupe_mis_a_jour', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('message_supprime', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
      socket!.on('membre_supprime', (message) {
      print('eto ary $message');
      // Handle user disconnected
      //socket!.emit('user_disconnected', 'USER_ID');
    });
    socket!.on('disconnect', (_) {
      print('déconnecté');
      // Handle user disconnected
      socket!.emit('user_disconnected', id);
    });

    socket!.on('message', (data) {
      print('message: $data');
      // Handle incoming message
    });

    // Add more event handlers as needed
  }

  void sendMessage(String message) {
    socket!.emit('message', message);
  }

  void disconnect() {
    socket!.disconnect();
  }
}

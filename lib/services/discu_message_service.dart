import 'dart:convert';
import 'package:dio/dio.dart';
import '../network/network_config.dart';
import '../models/direct_message.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class MessageService {

  final Dio dio;

  MessageService() : dio = NetworkConfig().client;

  // Méthode pour créer un message
  Future<bool?> createMessage(String contactId, Map<String,dynamic> messageData) async {
    try {
      final response = await dio.post(
        '/messages/personne/$contactId',
        data: jsonEncode(messageData),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to create message: ${response.data}');
        throw Exception('Failed to create message');
      }
    } catch (e) {
      print('Exception during message creation: $e');
      rethrow; // Rethrow the exception to propagate it further if necessary
    }
  }

  // Méthode pour obtenir un message par ID
  Future<DirectMessage?> getMessageById(String id) async {
    try {
      final response = await dio.get('/messages/$id');

      if (response.statusCode == 200) {
        return DirectMessage.fromJson(response.data);
      } else {
        print('Failed to load message: ${response.data}');
        throw Exception('Failed to load message');
      }
    } catch (e) {
      print('Exception during message retrieval: $e');
      rethrow;
    }
  }

  // Méthode pour mettre à jour un message
  Future<DirectMessage?> updateMessage(String id, Map<String, dynamic> messageData) async {
    try {
      final response = await dio.put(
        '/messages/$id',
        data: jsonEncode(messageData),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return DirectMessage.fromJson(response.data);
      } else {
        print('Failed to update message: ${response.data}');
        throw Exception('Failed to update message');
      }
    } catch (e) {
      print('Exception during message update: $e');
      rethrow;
    }
  }

  // Méthode pour supprimer un message
  Future<void> deleteMessage(String id) async {
    try {
      final response = await dio.delete('/messages/$id');

      if (response.statusCode != 204) {
        print('Failed to delete message: ${response.data}');
        throw Exception('Failed to delete message');
      }
    } catch (e) {
      print('Exception during message deletion: $e');
      rethrow;
    }
  }
  Future<bool> sendFileToPerson(String contactId, String filePath) async {
    try {
      String url = '/messages/personne/$contactId';
      
      // Déterminer le type MIME
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      
      // Créer un MultipartFile avec le type MIME correct
      MultipartFile file = await MultipartFile.fromFile(
        filePath,
        contentType: MediaType.parse(mimeType),
      );
      
      // Créer FormData
      FormData formData = FormData.fromMap({
        'file': file,
      });

      // Envoyer la requête POST avec Dio
      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to send file: ${response.data}');
        return false;
      }
    } catch (e) {
      print('Exception during file sending: $e');
      return false;
    }
  }

  // Méthode pour transférer un message
  Future<void> transferMessage(String contactId, String messageId) async {
    try {
      print('message: $messageId');
      print('contact: $contactId');
      final response = await dio.post('/messages/personne/$contactId/$messageId');

      if (response.statusCode != 201) {
        print('Failed to transfer message: ${response.data}');
        throw Exception('Failed to transfer message');
      }
    } catch (e) {
      print('Exception during message transfer: $e ');
      rethrow;
    }
  }
      Future<void> transferMessageGroupe(String groupId, String messageId) async {

        try {
    final response = await dio.post('/messages/groupe/$groupId/$messageId');

    if (response.statusCode != 201) {
      print('Failed to transfer group message: ${response.data}');
      throw Exception('Failed to transfer group message');
    }
 
    } catch (e) {
      print('Exception during message transfer: $e ');
      rethrow;
    }
  }

  // Méthode pour sauvegarder un message
  Future<void> saveMessage(String id) async {
    try {
      final response = await dio.post('/messages/$id');

      if (response.statusCode != 200) {
        print('Failed to save message: ${response.data}');
        throw Exception('Failed to save message');
      }
    } catch (e) {
      print('Exception during message saving: $e');
      rethrow;
    }
  }

  // Nouvelle méthode pour recevoir des messages depuis une URL
  Future<List<DirectMessage>> receiveMessagesFromUrl(String contactId) async {
    try {
      final response = await dio.get('/messages/personne/$contactId');

      if (response.statusCode == 200) {
        List<dynamic> messagesJson = response.data;
        return messagesJson.map((json) => DirectMessage.fromJson(json)).toList();
      } else {
        print('Failed to receive messages: ${response.data}');
        throw Exception('Failed to receive messages');
      }
    } catch (e) {
      print('Exception during message retrieval from URL: $e');
      rethrow;
    }
  }

  // Nouvelle méthode pour envoyer des messages à une URL
  Future<void> sendMessagesToUrl(String contactId, List<DirectMessage> messages) async {
    try {
      List<Map<String, dynamic>> messagesData = messages.map((msg) => msg.toJson()).toList();
      final response = await dio.post(
        '/messages/personne/$contactId',
        data: jsonEncode(messagesData),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('Response status code: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {

      } else {
        print('Failed to send messages: ${response.data}');
        throw Exception('Failed to send messages');
      }
    } catch (e) {
      print('Exception during message sending to URL: $e');
      rethrow;
    }
  }

}
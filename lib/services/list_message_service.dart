import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/messages.dart';
import '../network/network_config.dart';

class MessageService {
  final Dio dio = NetworkConfig().client;
  final String baseUrl = 'http://mahm.tempest.dov:3000';

  Future<List<Conversation>> getConversationsWithContact(String userId) async {
    final response = await dio.get('$baseUrl/dernierConversation');

    if (response.statusCode == 200) {
      List<dynamic> body = response.data;
      List<Conversation> conversations = [];

      for (var conv in body) {
        if (!conv['isGroup']) {
          conversations.add(Conversation.fromJson(conv));
        }
      }
      return conversations;
    } else {
      throw Exception('Failed to load conversations with contact');
    }
  }

  Future<List<Conversation>> getConversationsWithGroup(String userId) async {
    final response = await dio.get('$baseUrl/dernierConversation');

    if (response.statusCode == 200) {
      List<dynamic> body = response.data;
      List<Conversation> conversations = [];

      for (var conv in body) {
        if (conv['isGroup']) {
          conversations.add(Conversation.fromJson(conv));
        }
      }
      return conversations;
    } else {
      throw Exception('Failed to load conversations with group');
    }
  }

  Future<void> sendMessageToContact(String contactId, Map<String, dynamic> data) async {
    final response = await dio.post(
      '$baseUrl/messages/personne/$contactId',
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
      data: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message to contact');
    }
  }

  Future<void> sendMessageToGroup(String groupId, Map<String, dynamic> data) async {
    final response = await dio.post(
      '$baseUrl/messages/groupe/$groupId',
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
      data: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message to group');
    }
  }

  Future<void> transferMessageToContact(String contactId, String messageId) async {
    final response = await dio.post(
      '$baseUrl/messages/personne/$contactId/$messageId',
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to transfer message to contact');
    }
  }

  Future<void> transferMessageToGroup(String groupId, String messageId) async {
    final response = await dio.post(
      '$baseUrl/messages/groupe/$groupId/$messageId',
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to transfer message to group');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final response = await dio.delete(
      '$baseUrl/messages/$messageId',
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete message');
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/messages.dart';

class MessageService {
  final String baseUrl = 'http://mahm.tempest.dov';
  final storage = FlutterSecureStorage();

  Future<List<Conversation>> getConversationsWithContact(String contactId) async {
    final response = await http.get(Uri.parse('$baseUrl/messages/personne/$contactId'));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Conversation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load conversations with contact');
    }
  }

  Future<List<Conversation>> getConversationsWithGroup(String groupId) async {
    final response = await http.get(Uri.parse('$baseUrl/messages/groupe/$groupId'));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Conversation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load conversations with group');
    }
  }

  Future<void> sendMessageToContact(String contactId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/personne/$contactId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message to contact');
    }
  }

  Future<void> sendMessageToGroup(String groupId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/groupe/$groupId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message to group');
    }
  }

  Future<void> transferMessageToContact(String contactId, String messageId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/personne/$contactId/$messageId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to transfer message to contact');
    }
  }

  Future<void> transferMessageToGroup(String groupId, String messageId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/groupe/$groupId/$messageId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to transfer message to group');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/messages/$messageId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete message');
    }
  }
}

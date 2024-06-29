import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/direct_message.dart';

class MessageService {
  final String baseUrl;

  MessageService({required this.baseUrl});

  Future<DirectMessage?> createMessage(Map<String, dynamic> messageData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messageData),
    );

    if (response.statusCode == 201) {
      return DirectMessage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create message');
    }
  }

  Future<DirectMessage?> getMessageById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/messages/$id'));

    if (response.statusCode == 200) {
      return DirectMessage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load message');
    }
  }

  Future<DirectMessage?> updateMessage(String id, Map<String, dynamic> messageData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/messages/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messageData),
    );

    if (response.statusCode == 200) {
      return DirectMessage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update message');
    }
  }

  Future<void> deleteMessage(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/messages/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete message');
    }
  }
}

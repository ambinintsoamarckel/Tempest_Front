import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/discu_direct_message.dart';

class CustomHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Intercept and manipulate cookies here before sending the request
    // Example: Adding a custom cookie
    request.headers['cookie'] = 'your_custom_cookie=cookie_value';

    // You can also modify headers, authenticate requests, etc., as needed

    return _inner.send(request);
  }
}

class MessageService {
  final String baseUrl;
  final http.Client client;

  MessageService({required this.baseUrl}) : client = CustomHttpClient();

  // Méthode pour créer un message
  Future<DirectMessage?> createMessage(Map<String, dynamic> messageData) async {
    final response = await client.post(
      Uri.parse('$baseUrl/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messageData),
    );

    if (response.statusCode == 201) {
      return DirectMessage.fromJson(jsonDecode(response.body));
    } else {
      print('Failed to create message: ${response.body}');
      throw Exception('Failed to create message');
    }
  }

  // Méthode pour obtenir un message par ID
  Future<DirectMessage?> getMessageById(String id) async {
    final response = await client.get(Uri.parse('$baseUrl/messages/$id'));

    if (response.statusCode == 200) {
      return DirectMessage.fromJson(jsonDecode(response.body));
    } else {
      print('Failed to load message: ${response.body}');
      throw Exception('Failed to load message');
    }
  }

  // Méthode pour mettre à jour un message
  Future<DirectMessage?> updateMessage(String id, Map<String, dynamic> messageData) async {
    final response = await client.put(
      Uri.parse('$baseUrl/messages/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messageData),
    );

    if (response.statusCode == 200) {
      return DirectMessage.fromJson(jsonDecode(response.body));
    } else {
      print('Failed to update message: ${response.body}');
      throw Exception('Failed to update message');
    }
  }

  // Méthode pour supprimer un message
  Future<void> deleteMessage(String id) async {
    final response = await client.delete(Uri.parse('$baseUrl/messages/$id'));

    if (response.statusCode != 204) {
      print('Failed to delete message: ${response.body}');
      throw Exception('Failed to delete message');
    }
  }

  // Méthode pour transférer un message
  Future<void> transferMessage(String id) async {
    final response = await client.post(Uri.parse('$baseUrl/messages/personne/:contactId/$id'));

    if (response.statusCode != 200) {
      print('Failed to transfer message: ${response.body}');
      throw Exception('Failed to transfer message');
    }
  }

  // Méthode pour sauvegarder un message
  Future<void> saveMessage(String id) async {
    final response = await client.post(Uri.parse('$baseUrl/messages/$id'));

    if (response.statusCode != 200) {
      print('Failed to save message: ${response.body}');
      throw Exception('Failed to save message');
    }
  }

  // Nouvelle méthode pour recevoir des messages depuis une URL
  Future<List<DirectMessage>> receiveMessagesFromUrl(String url) async {
    final response = await client.get(Uri.parse('$baseUrl/messages/personne/:contactId'));

    if (response.statusCode == 200) {
      List<dynamic> messagesJson = jsonDecode(response.body);
      return messagesJson.map((json) => DirectMessage.fromJson(json)).toList();
    } else {
      print('Failed to receive messages: ${response.body}');
      throw Exception('Failed to receive messages');
    }
  }

  // Nouvelle méthode pour envoyer des messages à une URL
  Future<void> sendMessagesToUrl(String url, List<DirectMessage> messages) async {
    List<Map<String, dynamic>> messagesData = messages.map((msg) => msg.toJson()).toList();
    final response = await client.post(
      Uri.parse('$baseUrl/messages/personne/:contactId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messagesData),
    );

    if (response.statusCode != 200) {
      print('Failed to send messages: ${response.body}');
      throw Exception('Failed to send messages');
    }
  }
}

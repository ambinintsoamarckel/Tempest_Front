import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/messages.dart';

class ConversationService {
  final String baseUrl;

  ConversationService({required this.baseUrl});

  Future<List<Conversation>> getConversations() async {
    final response = await http.get(Uri.parse('$baseUrl/conversations'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Conversation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load conversations');
    }
  }
}

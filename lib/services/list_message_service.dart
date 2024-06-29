import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/messages.dart';
import '../network/network_config.dart';

class MessageService {
  final Dio dio = NetworkConfig().client;

  Future<List<Conversation>> getConversationsWithContact(String userId) async {
    final response = await dio.get('/dernierConversation');

    if (response.statusCode == 200) {
      List<dynamic> body = response.data;
      List<Conversation> conversations = [];

      for (var conv in body) {
        if (conv != null && conv is Map<String, dynamic> && conv['contact']?['type'] != 'groupe') {
          conversations.add(Conversation.fromJson(conv));
        }
      }
      return conversations;
    } else {
      throw Exception('Failed to load conversations with contact');
    }
  }

}

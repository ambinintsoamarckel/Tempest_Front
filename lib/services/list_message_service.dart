import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/messages.dart';
import '../network/network_config.dart';

class MessageService {
  final Dio dio = NetworkConfig().client;

  Future<List<Conversation>> getConversationsWithContact() async {
    final response = await dio.get('/dernierConversation');

    if (response.statusCode == 200) {
      List<dynamic> data = response.data;
      return data.map((json) => Conversation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load conversations');
    }
  }
}

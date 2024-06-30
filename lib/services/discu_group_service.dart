import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/group_message.dart';
import '../network/network_config.dart';

class GroupChatService {
  final String baseUrl;
  final Dio dio = NetworkConfig().client;

  GroupChatService({required this.baseUrl});

  // Method to create a group message
  Future<GroupMessage?> createGroupMessage(String groupId, Map<String, dynamic> messageData) async {
    final response = await dio.post(
      '/messages/groupe/$groupId',
      data: jsonEncode(messageData),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode == 201) {
      return GroupMessage.fromJson(response.data);
    } else {
      print('Failed to create group message: ${response.data}');
      throw Exception('Failed to create group message');
    }
  }

  // Method to get a group message by ID
  Future<GroupMessage?> getGroupMessageById(String id, String messageId) async {
    final response = await dio.get('/groupes/$id');

    if (response.statusCode == 200) {
      return GroupMessage.fromJson(response.data);
    } else {
      print('Failed to load group message: ${response.data}');
      throw Exception('Failed to load group message');
    }
  }

  // Method to update a group message
  Future<GroupMessage?> updateGroupMessage(String id, Map<String, dynamic> messageData) async {
    final response = await dio.put(
      '/groupes/$id',
      data: jsonEncode(messageData),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode == 200) {
      return GroupMessage.fromJson(response.data);
    } else {
      print('Failed to update group message: ${response.data}');
      throw Exception('Failed to update group message');
    }
  }

  // Method to delete a group message
  Future<void> deleteGroupMessage(String groupId, String messageId) async {
    final response = await dio.delete('/messages/groupe/$groupId/$messageId');

    if (response.statusCode != 204) {
      print('Failed to delete group message: ${response.data}');
      throw Exception('Failed to delete group message');
    }
  }

  // Method to transfer a group message
  Future<void> transferGroupMessage(String groupId, String messageId) async {
    final response = await dio.post('/messages/groupe/$groupId/$messageId');

    if (response.statusCode != 200) {
      print('Failed to transfer group message: ${response.data}');
      throw Exception('Failed to transfer group message');
    }
  }

  // Method to save a group message
  Future<void> saveGroupMessage(String groupId, String messageId) async {
    final response = await dio.post('/groups/$groupId/messages/$messageId/save');

    if (response.statusCode != 200) {
      print('Failed to save group message: ${response.data}');
      throw Exception('Failed to save group message');
    }
  }

  // Method to receive group messages
  Future<List<GroupMessage>> receiveGroupMessages(String groupId) async {
    final response = await dio.get('/messages/groupe/$groupId');

    if (response.statusCode == 200) {
      List<dynamic> messagesJson = response.data;
      return messagesJson.map((json) => GroupMessage.fromJson(json)).toList();
    } else {
      print('Failed to receive group messages: ${response.data}');
      throw Exception('Failed to receive group messages');
    }
  }

  // Method to send group messages
  Future<void> sendGroupMessages(String groupId, List<GroupMessage> messages) async {
    List<Map<String, dynamic>> messagesData = messages.map((msg) => msg.toJson()).toList();
    final response = await dio.post(
      '/messages/groupe/$groupId',
      data: jsonEncode(messagesData),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode != 200) {
      print('Failed to send group messages: ${response.data}');
      throw Exception('Failed to send group messages');
    }
  }

  // Method to create a new group
  Future<void> createGroup(Map<String, dynamic> groupData) async {
    final response = await dio.post(
      '/groupes',
      data: jsonEncode(groupData),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode != 201) {
      print('Failed to create group: ${response.data}');
      throw Exception('Failed to create group');
    }
  }

  // Method to add a member to a group
  Future<void> addMemberToGroup(String id, String utilisateurId, Map<String, dynamic> memberData) async {
    final response = await dio.post(
      '/groupes/$id/membres/$utilisateurId',
      data: jsonEncode(memberData),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode != 201) {
      print('Failed to add member to group: ${response.data}');
      throw Exception('Failed to add member to group');
    }
  }

  // Method to remove a member from a group
  Future<void> removeMemberFromGroup(String id, String utilisateurId) async {
    final response = await dio.delete('/groupes/$id/membres/$utilisateurId');

    if (response.statusCode != 204) {
      print('Failed to remove member from group: ${response.data}');
      throw Exception('Failed to remove member from group');
    }
  }

  // Method to change group photo
  Future<void> changeGroupPhoto(String id, File newPhoto) async {
    FormData formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(newPhoto.path, filename: newPhoto.path.split('/').last),
    });

    final response = await dio.put(
      '/groupes/$id/changePhoto',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    if (response.statusCode != 200) {
      print('Failed to change group photo: ${response.data}');
      throw Exception('Failed to change group photo');
    }
  }
}

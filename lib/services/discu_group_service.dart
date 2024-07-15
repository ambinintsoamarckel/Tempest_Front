import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/group_message.dart';
import '../network/network_config.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
class GroupChatService {
  final Dio dio = NetworkConfig().client;

  GroupChatService();

  // Method to create a group message
  Future<bool?> createMessage(String groupId, Map<String, dynamic> messageData) async {
    final response = await dio.post(
      '/messages/groupe/$groupId',
      data: jsonEncode(messageData),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print('Failed to create group message: ${response.data}');
      throw Exception('Failed to create group message');
    }
  }

  // Method to get a group message by ID
  Future<GroupMessage?> getGroupMessageById(String groupId, String messageId) async {
    final response = await dio.get('/messages/groupe/$groupId/$messageId');

    if (response.statusCode == 200) {
      return GroupMessage.fromJson(response.data);
    } else {
      print('Failed to load group message: ${response.data}');
      throw Exception('Failed to load group message');
    }
  }

  // Method to update a group message
  Future<Group> updateGroup(String groupId, Map<String, dynamic> data) async {
try {
      final response = await dio.put(
      '/groupes/$groupId',
      data: jsonEncode(data),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode == 200) {
      return Group.fromJson(response.data);
    } else {
      print('Failed to update group message: ${response.data}');
      throw Exception('Failed to update group message');
    }
  
} catch (e) {
          print('Failed to update user: $e');
        rethrow;
  
}
  }

  // Method to delete a group message
  Future<void> deleteMessage(String groupId, String messageId) async {
    final response = await dio.delete('/messages/groupe/$groupId/$messageId');

    if (response.statusCode != 204) {
      print('Failed to delete group message: ${response.data}');
      throw Exception('Failed to delete group message');
    }
  }

  // Method to transfer a group message
  Future<void> transferMessage(String contactId, String messageId) async {
    try {

      final response = await dio.post('/messages/personne/$contactId/$messageId');

      if (response.statusCode != 201) {
        print('Failed to transfer message: ${response.data}');
        /* throw Exception('Failed to transfer message'); */
      }
    } catch (e) {
      print('Exception during message transfer: $e ');
      rethrow;
    }
  }
    Future<void> transferMessageGroupe(String groupId, String messageId) async {
    final response = await dio.post('/messages/groupe/$groupId/$messageId');

    if (response.statusCode != 201) {
      print('Failed to transfer group message: ${response.data}');
      throw Exception('Failed to transfer group message');
    }
  }

  // Method to save a group message
  Future<void> saveGroupMessage(String groupId, String messageId) async {
    final response = await dio.post('/messages/groupe/$groupId/$messageId/save');

    if (response.statusCode != 200) {
      print('Failed to save group message: ${response.data}');
      throw Exception('Failed to save group message');
    }
  }

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
  Future<Group> addMemberToGroup(String id, String utilisateurId, Map<String, dynamic> memberData) async {
    try {

    final response = await dio.post(
      '/groupes/$id/membres/$utilisateurId',
      data: jsonEncode(memberData),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode != 201) {
      print('Failed to add member to group: ${response.data}');
      throw Exception('Failed to add member to group');
    }
    return Group.fromJson(response.data);      
    } catch (e) {
        print('Failed to add user: $e');
        rethrow;
      
    }
  }
  Future<Group> quitGroup(String id) async {
    try {

    final response = await dio.delete('/me/quitGroup/$id');

    if (response.statusCode != 204) {
      print('Failed to remove member from group: ${response.data}');
      throw Exception('Failed to remove member from group');
    }
    return Group.fromJson(response.data);
      
    } catch (e) {
        print('Failed to remove user: $e');
        rethrow;
      
    }
  }

  // Method to remove a member from a group
  Future<Group> removeMemberFromGroup(String id, String utilisateurId) async {
    try {

    final response = await dio.delete('/groupes/$id/membres/$utilisateurId');

    if (response.statusCode != 200) {
      print('Failed to remove member from group: ${response.data}');
      throw Exception('Failed to remove member from group');
    }
    return Group.fromJson(response.data);
      
    } catch (e) {
        print('Failed to remove user: $e');
        rethrow;
      
    }
  }
    Future<bool> sendFileToGroup(String groupId, String filePath) async {
    try {
      String url = '/messages/groupe/$groupId';
      
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

  // Method to change group photo
  Future<Group> changeGroupPhoto(String id, String newPhoto) async {
    try {
        final mimeType = lookupMimeType(newPhoto) ?? 'application/octet-stream';
      
      // Créer un MultipartFile avec le type MIME correct
      MultipartFile file = await MultipartFile.fromFile(
        newPhoto,
        contentType: MediaType.parse(mimeType),
      );
      
      // Créer FormData
      FormData formData = FormData.fromMap({
        'photo': file,
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
    return Group.fromJson(response.data);
  
      
    } catch (e) {
            print('Exception during file sending: $e');
      rethrow;
      
    }
      // Déterminer le type MIME
  }
    
}

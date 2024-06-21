import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/discu_group_message.dart';

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

class GroupChatService {
  final String baseUrl;
  final http.Client client;

  GroupChatService({required this.baseUrl}) : client = CustomHttpClient();

  // Method to create a group message
  Future<GroupMessage?> createGroupMessage(String groupId, Map<String, dynamic> messageData) async {
    final response = await client.post(
      Uri.parse('$baseUrl/groups/$groupId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messageData),
    );

    if (response.statusCode == 201) {
      return GroupMessage.fromJson(jsonDecode(response.body));
    } else {
      print('Failed to create group message: ${response.body}');
      throw Exception('Failed to create group message');
    }
  }

  // Method to get a group message by ID
  Future<GroupMessage?> getGroupMessageById(String groupId, String messageId) async {
    final response = await client.get(Uri.parse('$baseUrl/groups/$groupId/messages/$messageId'));

    if (response.statusCode == 200) {
      return GroupMessage.fromJson(jsonDecode(response.body));
    } else {
      print('Failed to load group message: ${response.body}');
      throw Exception('Failed to load group message');
    }
  }

  // Method to update a group message
  Future<GroupMessage?> updateGroupMessage(String groupId, String messageId, Map<String, dynamic> messageData) async {
    final response = await client.put(
      Uri.parse('$baseUrl/groups/$groupId/messages/$messageId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messageData),
    );

    if (response.statusCode == 200) {
      return GroupMessage.fromJson(jsonDecode(response.body));
    } else {
      print('Failed to update group message: ${response.body}');
      throw Exception('Failed to update group message');
    }
  }

  // Method to delete a group message
  Future<void> deleteGroupMessage(String groupId, String messageId) async {
    final response = await client.delete(Uri.parse('$baseUrl/groups/$groupId/messages/$messageId'));

    if (response.statusCode != 204) {
      print('Failed to delete group message: ${response.body}');
      throw Exception('Failed to delete group message');
    }
  }

  // Method to transfer a group message
  Future<void> transferGroupMessage(String groupId, String messageId) async {
    final response = await client.post(Uri.parse('$baseUrl/groups/$groupId/messages/$messageId/transfer'));

    if (response.statusCode != 200) {
      print('Failed to transfer group message: ${response.body}');
      throw Exception('Failed to transfer group message');
    }
  }

  // Method to save a group message
  Future<void> saveGroupMessage(String groupId, String messageId) async {
    final response = await client.post(Uri.parse('$baseUrl/groups/$groupId/messages/$messageId/save'));

    if (response.statusCode != 200) {
      print('Failed to save group message: ${response.body}');
      throw Exception('Failed to save group message');
    }
  }

  // Method to receive group messages
  Future<List<GroupMessage>> receiveGroupMessages(String groupId) async {
    final response = await client.get(Uri.parse('$baseUrl/messages/groups/$groupId'));

    if (response.statusCode == 200) {
      List<dynamic> messagesJson = jsonDecode(response.body);
      return messagesJson.map((json) => GroupMessage.fromJson(json)).toList();
    } else {
      print('Failed to receive group messages: ${response.body}');
      throw Exception('Failed to receive group messages');
    }
  }

  // Method to send group messages
  Future<void> sendGroupMessages(String groupId, List<GroupMessage> messages) async {
    List<Map<String, dynamic>> messagesData = messages.map((msg) => msg.toJson()).toList();
    final response = await client.post(
      Uri.parse('$baseUrl/messages/groups/$groupId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messagesData),
    );

    if (response.statusCode != 200) {
      print('Failed to send group messages: ${response.body}');
      throw Exception('Failed to send group messages');
    }
  }

  // Method to create a new group
  Future<void> createGroup(Map<String, dynamic> groupData) async {
    final response = await client.post(
      Uri.parse('$baseUrl/groups'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(groupData),
    );

    if (response.statusCode != 201) {
      print('Failed to create group: ${response.body}');
      throw Exception('Failed to create group');
    }
  }

  // Method to add a member to a group
  Future<void> addMemberToGroup(String groupId, Map<String, dynamic> memberData) async {
    final response = await client.post(
      Uri.parse('$baseUrl/groups/$groupId/members'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(memberData),
    );

    if (response.statusCode != 201) {
      print('Failed to add member to group: ${response.body}');
      throw Exception('Failed to add member to group');
    }
  }

  // Method to remove a member from a group
  Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    final response = await client.delete(Uri.parse('$baseUrl/groups/$groupId/members/$memberId'));

    if (response.statusCode != 204) {
      print('Failed to remove member from group: ${response.body}');
      throw Exception('Failed to remove member from group');
    }
  }

  // Method to change group photo
  Future<void> changeGroupPhoto(String groupId, File newPhoto) async {
    // Example assumes you are sending a file, adjust headers and body as needed
    final response = await client.put(
      Uri.parse('$baseUrl/groups/$groupId/changePhoto'),
      headers: {'Content-Type': 'multipart/form-data'},
      body: {'photo': newPhoto}, // Adjust this to how your backend expects the file
    );

    if (response.statusCode != 200) {
      print('Failed to change group photo: ${response.body}');
      throw Exception('Failed to change group photo');
    }
  }
}

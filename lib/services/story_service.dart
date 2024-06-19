import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stories.dart';

class StoryService {
  final String baseUrl;

  StoryService({required this.baseUrl});

  Future<Story?> createStory(Map<String, dynamic> storyData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(storyData),
    );

    if (response.statusCode == 201) {
      return Story.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create story');
    }
  }

  Future<Story?> getStoryById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/stories/$id'));

    if (response.statusCode == 200) {
      return Story.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load story');
    }
  }

  Future<Story?> updateStory(String id, Map<String, dynamic> storyData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/stories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(storyData),
    );

    if (response.statusCode == 200) {
      return Story.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update story');
    }
  }

  Future<void> deleteStory(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/stories/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete story');
    }
  }
}

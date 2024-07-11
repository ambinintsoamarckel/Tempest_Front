import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/stories.dart';
import '../network/network_config.dart';

class StoryService {
  final Dio dio = NetworkConfig().client;
  final storage = FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<Story?> createStory(Map<String, dynamic> storyData) async {
    final token = await _getToken();
    try {
      final response = await dio.post(
        '/me/addStory',
        data: FormData.fromMap(storyData),
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201) {
        return Story.fromJson(response.data);
      } else {
        throw Exception('Failed to create story');
      }
    } catch (e) {
      throw Exception('Failed to create story: $e');
    }
  }

  Future<Story?> getStoryById(String id) async {
    final token = await _getToken();
    try {
      final response = await dio.get(
        '/stories/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return Story.fromJson(response.data);
      } else {
        throw Exception('Failed to load story');
      }
    } catch (e) {
      throw Exception('Failed to load story: $e');
    }
  }

  Future<List<Story>> getStories() async {
    final token = await _getToken();
    try {
      final response = await dio.get(
        '/stories',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        List<Story> stories = (response.data as List).map((i) => Story.fromJson(i)).toList();
        return stories;
      } else {
        throw Exception('Failed to load stories');
      }
    } catch (e) {
      throw Exception('Failed to load stories: $e');
    }
  }

  Future<void> deleteStory(String id) async {
    final token = await _getToken();
    try {
      final response = await dio.delete(
        '/stories/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete story');
      }
    } catch (e) {
      throw Exception('Failed to delete story: $e');
    }
  }
}

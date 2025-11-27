import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/stories.dart';
import '../network/network_config.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../models/grouped_stories.dart' as group;

class StoryService {
  final Dio dio = NetworkConfig().client;
  final storage = const FlutterSecureStorage();

  /// Crée une story de type texte avec toutes les options de style
  Future<void> createStory(Map<String, dynamic> storyData) async {
    try {
      print('📤 [StoryService] Creating text story with data: $storyData');

      final response = await dio.post(
        '/me/addStory',
        data: FormData.fromMap(storyData),
      );

      if (response.statusCode == 201) {
        print('✅ [StoryService] Text story created successfully');
      } else {
        throw Exception('Failed to create story: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [StoryService] Failed to create story: $e');
      throw Exception('Failed to create story: $e');
    }
  }

  /// Crée une story avec un fichier (image/vidéo) et une légende optionnelle
  Future<void> createStoryFile(String filePath, {String? caption}) async {
    try {
      print('📤 [StoryService] Creating file story from: $filePath');
      if (caption != null) {
        print('📝 [StoryService] With caption: $caption');
      }

      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      print('🎯 [StoryService] Detected MIME type: $mimeType');

      MultipartFile file = await MultipartFile.fromFile(
        filePath,
        contentType: MediaType.parse(mimeType),
      );

      // Construire le FormData avec le fichier et la légende optionnelle
      Map<String, dynamic> formDataMap = {
        'file': file,
      };

      // Ajouter la légende si elle existe
      if (caption != null && caption.trim().isNotEmpty) {
        formDataMap['caption'] = caption.trim();
      }

      FormData formData = FormData.fromMap(formDataMap);

      final response = await dio.post(
        '/me/addStory',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201) {
        print('✅ [StoryService] File story created successfully');
      } else {
        throw Exception('Failed to create story: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [StoryService] Failed to create story: $e');
      throw Exception('Failed to create story: $e');
    }
  }

  Future<Story?> getStoryById(String id) async {
    try {
      final response = await dio.get('/stories/$id');

      if (response.statusCode == 200) {
        return Story.fromJson(response.data);
      } else {
        throw Exception('Failed to load story: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [StoryService] Failed to load story: $e');
      throw Exception('Failed to load story: $e');
    }
  }

  Future<Story?> getArchivesById(String id) async {
    try {
      final response = await dio.get('/archives/$id');

      if (response.statusCode == 200) {
        return Story.fromJson(response.data);
      } else {
        throw Exception('Failed to load archive: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [StoryService] Failed to load archive: $e');
      throw Exception('Failed to load archive: $e');
    }
  }

  Future<List<group.GroupedStory>> getStories() async {
    try {
      final response = await dio.get('/stories');

      if (response.statusCode == 200) {
        List<group.GroupedStory> stories = [];
        for (var userStories in response.data) {
          group.GroupedStory story = group.GroupedStory.fromJson(userStories);
          stories.add(story);
        }
        return stories;
      } else {
        throw Exception('Failed to load stories: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [StoryService] Failed to load stories: $e');
      throw Exception('Failed to load stories: $e');
    }
  }

  Future<void> deleteStory(String id) async {
    try {
      final response = await dio.delete('/stories/$id');

      if (response.statusCode != 204) {
        throw Exception('Failed to delete story: ${response.statusCode}');
      }
      print('✅ [StoryService] Story deleted successfully');
    } catch (e) {
      print('❌ [StoryService] Failed to delete story: $e');
      throw Exception('Failed to delete story: $e');
    }
  }
}

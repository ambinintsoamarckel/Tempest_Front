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

  Future<void> createStory(Map<String, dynamic> storyData) async {

    try {
      final response = await dio.post(
        '/me/addStory',
        data: FormData.fromMap(storyData),
      );

      if (response.statusCode == 201) {
        // Pas besoin de retourner l'objet Story ici car le serveur ne renvoie probablement pas l'objet complet après la création.
        // Vous pouvez ajouter des vérifications supplémentaires si nécessaire.
      } else {
        throw Exception('Failed to create story');
      }
    } catch (e) {
      throw Exception('Failed to create story: $e');
    }
  }

  Future<void> createStoryFile(String filePath) async {

    try {
       final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
        MultipartFile file = await MultipartFile.fromFile(
        filePath,
        contentType: MediaType.parse(mimeType),
      );
      
      FormData formData = FormData.fromMap({
        'file': file,
      });
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
        // Pas besoin de retourner l'objet Story ici car le serveur ne renvoie probablement pas l'objet complet après la création.
        // Vous pouvez ajouter des vérifications supplémentaires si nécessaire.
      } else {
        throw Exception('Failed to create story');
      }
    } catch (e) {
      throw Exception('Failed to create story: $e');
    }
  }

  Future<Story?> getStoryById(String id) async {

    try {
      final response = await dio.get(
        '/stories/$id',

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
    Future<Story?> getArchivesById(String id) async {

    try {
      final response = await dio.get(
        '/archives/$id',

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

  Future<List<group.GroupedStory>> getStories() async {

    try {
      final response = await dio.get(
        '/stories',

      );

      if (response.statusCode == 200) {
        List<group.GroupedStory> stories = [];
        for (var userStories in response.data) {
          group.GroupedStory story = group.GroupedStory.fromJson(userStories);
          stories.add(story);
   
        }
        return stories;
      } else {
        throw Exception('Failed to load stories');
      }
    } catch (e) {
      throw Exception('Failed to load stories: $e');
    }
  }

  Future<void> deleteStory(String id) async {

    try {
      final response = await dio.delete(
        '/stories/$id',
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete story');
      }
    } catch (e) {
      throw Exception('Failed to delete story: $e');
    }
  }
}

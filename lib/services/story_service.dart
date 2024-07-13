import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/stories.dart';
import '../network/network_config.dart';

class StoryService {
  final Dio dio = NetworkConfig().client;
  final storage = FlutterSecureStorage();

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

  Future<void> createStoryFile(Map<String, dynamic> storyData) async {

    try {
      final response = await dio.post(
        '/me/addStory',
        data: []
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
        final userJson = response.data['utilisateur'];
        User user = User.fromJson(userJson);
        return Story.fromJson(response.data['story'], user);
      } else {
        throw Exception('Failed to load story');
      }
    } catch (e) {
      throw Exception('Failed to load story: $e');
    }
  }

  Future<List<Story>> getStories() async {

    try {
      final response = await dio.get(
        '/stories',

      );

      if (response.statusCode == 200) {
        List<Story> stories = [];
        for (var userStories in response.data) {
          User user = User.fromJson(userStories['utilisateur']);
          for (var storyJson in userStories['stories']) {
            Story story = Story.fromJson(storyJson, user);
            stories.add(story);
          }
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

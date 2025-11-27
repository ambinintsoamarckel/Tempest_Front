// models/user.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'stories.dart';
import 'user.dart';

class GroupedStory {
  final User utilisateur;
  final List<Story> stories;

  GroupedStory({
    required this.utilisateur,
    required this.stories,
  });

  factory GroupedStory.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw Exception('GroupedStory JSON is null');
    }

    // ✅ Parser l'utilisateur de façon robuste
    User user;
    try {
      if (json['utilisateur'] == null) {
        throw Exception('utilisateur is null');
      }

      if (json['utilisateur'] is! Map<String, dynamic>) {
        throw Exception(
            'utilisateur is not a Map: ${json['utilisateur'].runtimeType}');
      }

      user = User.fromJson(json['utilisateur']);
    } catch (e) {
      print('⚠️ [GroupedStory] Error parsing utilisateur: $e');
      user = User(
        id: 'unknown',
        nom: 'Utilisateur inconnu',
        email: 'unknown@example.com',
      );
    }

    // ✅ Parser les stories de façon robuste
    List<Story> storiesList = [];
    try {
      if (json['stories'] != null && json['stories'] is List) {
        var storiesFromJson = json['stories'] as List;

        for (var storyJson in storiesFromJson) {
          try {
            // Vérifier que storyJson n'est pas null ET est un Map
            if (storyJson == null) {
              print('! [GroupedStory] Skipping null story');
              continue;
            }

            if (storyJson is! Map<String, dynamic>) {
              print(
                  '! [GroupedStory] Failed to parse individual story: type \'${storyJson.runtimeType}\' is not a subtype of type \'Map<String, dynamic>\'');
              continue;
            }

            Story story = Story.fromJson(storyJson);
            storiesList.add(story);
          } catch (e) {
            print('! [GroupedStory] Failed to parse individual story: $e');
            continue;
          }
        }
      }
    } catch (e) {
      print('⚠️ [GroupedStory] Error parsing stories list: $e');
    }

    if (storiesList.isEmpty) {
      print('! [GroupedStory] No valid stories found for user ${user.nom}');
    }

    return GroupedStory(
      utilisateur: user,
      stories: storiesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'utilisateur': utilisateur.toJson(),
      'stories': stories.map((s) => s.toJson()).toList(),
    };
  }

  Story? get firstStory => stories.isNotEmpty ? stories.first : null;
  int get storyCount => stories.length;
  bool get hasStories => stories.isNotEmpty;
}

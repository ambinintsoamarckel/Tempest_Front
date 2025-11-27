// models/story_models.dart
// 📦 Tous les modèles liés aux stories centralisés ici
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'user.dart';

// ============================================================================
// ENUMS & STORY CONTENT
// ============================================================================

enum StoryType { texte, image, video }

class StoryContent {
  final StoryType type;
  final String? texte;
  final String? image;
  final String? video;

  // Champs pour les stories texte stylisées
  final String? backgroundColor;
  final String? textColor;
  final String? textAlign;
  final double? fontSize;
  final String? fontWeight;

  // Légende pour images/vidéos
  final String? caption;

  StoryContent({
    required this.type,
    this.texte,
    this.image,
    this.video,
    this.backgroundColor,
    this.textColor,
    this.textAlign,
    this.fontSize,
    this.fontWeight,
    this.caption,
  });

  factory StoryContent.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return StoryContent(type: StoryType.texte);
    }

    StoryType storyType = StoryType.texte;
    try {
      if (json['type'] != null) {
        storyType = StoryType.values.firstWhere(
          (e) => describeEnum(e) == json['type'],
          orElse: () => StoryType.texte,
        );
      }
    } catch (e) {
      print('⚠️ Erreur parsing type: $e');
    }

    return StoryContent(
      type: storyType,
      texte: json['texte'],
      image: json['image'],
      video: json['video'],
      backgroundColor: json['backgroundColor'],
      textColor: json['textColor'],
      textAlign: json['textAlign'],
      fontSize: json['fontSize']?.toDouble(),
      fontWeight: json['fontWeight'],
      caption: json['caption'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'type': describeEnum(type),
    };

    if (texte != null) data['texte'] = texte;
    if (image != null) data['image'] = image;
    if (video != null) data['video'] = video;
    if (backgroundColor != null) data['backgroundColor'] = backgroundColor;
    if (textColor != null) data['textColor'] = textColor;
    if (textAlign != null) data['textAlign'] = textAlign;
    if (fontSize != null) data['fontSize'] = fontSize;
    if (fontWeight != null) data['fontWeight'] = fontWeight;
    if (caption != null) data['caption'] = caption;

    return data;
  }
}
class Story {
  final String id;
  final StoryContent contenu;
  final DateTime creationDate;
  final DateTime expirationDate;
  final List<User> vues;
  final User user;

  Story({
    required this.id,
    required this.contenu,
    required this.creationDate,
    required this.expirationDate,
    required this.vues,
    required this.user,
  });

  factory Story.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw Exception('Story JSON is null');
    }

    // ✅ Parser les vues de façon robuste
    List<User> vuesList = [];
    try {
      if (json['vues'] != null && json['vues'] is List) {
        var vuesFromJson = json['vues'] as List;
        vuesList = vuesFromJson
            .where((item) {
              // Filtrer les null et les non-Map (comme les strings d'IDs)
              if (item == null) return false;
              if (item is! Map<String, dynamic>) {
                print(
                    '! Erreur parsing vues: type \'${item.runtimeType}\' is not a subtype of type \'Map<String, dynamic>\'');
                return false;
              }
              return true;
            })
            .map((i) => User.fromJson(i))
            .toList();
      }
    } catch (e) {
      print('⚠️ Erreur parsing vues: $e');
    }

    // ✅ Parser les dates avec fallback
    DateTime creationDate = DateTime.now();
    DateTime expirationDate = DateTime.now().add(const Duration(hours: 24));

    try {
      if (json['dateCreation'] != null) {
        creationDate = DateTime.parse(json['dateCreation']);
      }
    } catch (e) {
      print('⚠️ Erreur parsing dateCreation: $e');
    }

    try {
      if (json['dateExpiration'] != null) {
        expirationDate = DateTime.parse(json['dateExpiration']);
      }
    } catch (e) {
      print('⚠️ Erreur parsing dateExpiration: $e');
    }

    // ✅ Parser l'utilisateur
    User storyUser;
    try {
      if (json['utilisateur'] == null) {
        throw Exception('utilisateur is null');
      }
      storyUser = User.fromJson(json['utilisateur']);
    } catch (e) {
      print('⚠️ Erreur parsing utilisateur: $e');
      storyUser = User(
        id: 'unknown',
        nom: 'Utilisateur inconnu',
        email: 'unknown@example.com',
      );
    }

    return Story(
      id: json['_id'] ?? 'unknown',
      contenu: StoryContent.fromJson(json['contenu']),
      creationDate: creationDate,
      expirationDate: expirationDate,
      vues: vuesList,
      user: storyUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'contenu': contenu.toJson(),
      'dateCreation': creationDate.toIso8601String(),
      'dateExpiration': expirationDate.toIso8601String(),
      'vues': vues.map((v) => v.toJson()).toList(),
      'utilisateur': user.toJson(),
    };
  }

  bool get isStyledTextStory {
    return contenu.type == StoryType.texte &&
        (contenu.backgroundColor != null || contenu.textColor != null);
  }

  bool get hasCaption {
    return contenu.caption != null && contenu.caption!.isNotEmpty;
  }
}

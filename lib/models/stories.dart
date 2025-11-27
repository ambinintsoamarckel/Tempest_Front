// models/stories.dart
import 'package:flutter/foundation.dart';

enum StoryType { texte, image, video }

class StoryContent {
  final StoryType type;
  final String? texte;
  final String? image;
  final String? video;

  // ✅ Nouveaux champs pour les stories texte stylisées
  final String? backgroundColor;
  final String? textColor;
  final String? textAlign;
  final double? fontSize;
  final String? fontWeight;

  // ✅ Nouveau champ pour les légendes des images/vidéos
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

  factory StoryContent.fromJson(Map<String, dynamic> json) {
    return StoryContent(
      type: StoryType.values.firstWhere(
        (e) => describeEnum(e) == json['type'],
        orElse: () => StoryType.texte,
      ),
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

class User {
  final String id;
  final String name;
  final String email;
  final String? photo;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.photo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['nom'],
      email: json['email'],
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': name,
      'email': email,
      'photo': photo,
    };
  }
}

// models/story.dart
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

  factory Story.fromJson(Map<String, dynamic> json) {
    var vuesFromJson = json['vues'] as List;
    List<User> vuesList = vuesFromJson.map((i) => User.fromJson(i)).toList();

    return Story(
      id: json['_id'],
      contenu: StoryContent.fromJson(json['contenu']),
      creationDate: DateTime.parse(json['dateCreation']),
      expirationDate: DateTime.parse(json['dateExpiration']),
      vues: vuesList,
      user: User.fromJson(json['utilisateur']),
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

  /// Helper pour savoir si c'est une story texte stylisée
  bool get isStyledTextStory {
    return contenu.type == StoryType.texte &&
        (contenu.backgroundColor != null || contenu.textColor != null);
  }

  /// Helper pour savoir si la story a une légende
  bool get hasCaption {
    return contenu.caption != null && contenu.caption!.isNotEmpty;
  }
}

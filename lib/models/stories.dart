// models/user.dart
import 'package:flutter/foundation.dart';

enum StoryType { texte, image,  video }

class StoryContent {
  final StoryType type;
  final String? texte;
  final String? image;
  final String? video;

  StoryContent({
    required this.type,
    this.texte,
    this.image,
    this.video,
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
    );
  }
}
class User {
  final String id;
  final String name;
  final String email;
  final String? photo;

  User({required this.id, required this.name, required this.email,required this.photo });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['nom'],
      email: json['email'],
      photo: json['photo'] ,
    );
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
    var vuesFromJson =json['vues'] as List;
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
}

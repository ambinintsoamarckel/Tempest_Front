// models/user.dart
class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['nom'],
      email: json['email'],
    );
  }
}

// models/story.dart
class Story {
  final String id;
  final String type;
  final String content;
  final DateTime creationDate;
  final DateTime expirationDate;
  final List<dynamic> vues;
  final User user;

  Story({
    required this.id,
    required this.type,
    required this.content,
    required this.creationDate,
    required this.expirationDate,
    required this.vues,
    required this.user,
  });

  factory Story.fromJson(Map<String, dynamic> json, User user) {
    return Story(
      id: json['_id'],
      type: json['contenu']['type'],
      content: json['contenu']['texte'],
      creationDate: DateTime.parse(json['dateCreation']),
      expirationDate: DateTime.parse(json['dateExpiration']),
      vues: json['vues'],
      user: user,
    );
  }
}

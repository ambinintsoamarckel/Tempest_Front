/* class User {
  final String id;
  final String nom;
  final String email;
  final String? photo;

  User({required this.id, required this.nom, required this.email, this.photo});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      nom: json['nom'],
      email: json['email'],
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'email': email,
      'photo': photo,
    };
  }
}
class Group {
  final String id;
  final String nom;
  final String? description;
  final String? photo;
  User createur;

  Group({required this.id, required this.nom, required this.description, this.photo, required this.createur});

  factory Group.fromJson(Map<String, dynamic> json) {
    var membresFromJson = json['membres'] as List;
    List<User> membresList = membresFromJson.map((i) => User.fromJson(i)).toList();

    return Group(
      id: json['_id'],
      nom: json['nom'],
      createur: User.fromJson(json['createur']),
      description: json['description'],
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'description': description,
      'photo': photo,
    };
  }
}

class UserModel {
  final String uid;
  final String email;
  final String nom;
  late final String photo;
  final String presence;
  final List<Group> groupes;
  

  UserModel({
    required this.uid,
    required this.email,
    required this.nom,
    required this.photo,
    required this.presence,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['_id'] ?? '',
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      photo: json['photo'] ?? '',
      presence: json['presence'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': uid,
      'email': email,
      'nom': nom,
      'photo': photo,
      'presence': presence,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? nom,
    String? photo,
    String? presence,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      photo: photo ?? this.photo,
      presence: presence ?? this.presence,
    );
  }
}
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

 */
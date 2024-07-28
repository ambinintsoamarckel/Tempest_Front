import '../models/grouped_stories.dart';
class Group {
  final String id;
  final String nom;
  final String? description;
  final String? photo;


  Group({required this.id, required this.nom, required this.description, this.photo, });

  factory Group.fromJson(Map<String, dynamic> json) {

    return Group(
      id: json['_id'],
      nom: json['nom'],
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
  late final String? photo;
  final String presence;
  final List<Group> groupes;
  final List<Story> stories;
  final List<Story>archives;
  

  UserModel({
    required this.uid,
    required this.email,
    required this.nom,
    required this.photo,
    required this.presence,
    required this.archives,
    required this.groupes,
    required this.stories,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var archivesFromJson = json['archives'] as List;
    var storiesFromJson = json['stories'] as List;
    var groupesFromJson =json['groupes'] as List;
    List<Story> archivesList = archivesFromJson.map((i) => Story.fromJson(i)).toList();
    List<Story> storiesList = storiesFromJson.map((i) => Story.fromJson(i)).toList();
    List<Group> groupesList=groupesFromJson.map((i)=> Group.fromJson(i)).toList();
    return UserModel(
      uid: json['_id'] ?? '',
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      photo: json['photo'],
      presence: json['presence'] ?? '',
      stories: storiesList,
      archives: archivesList,
      groupes: groupesList,
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
}


import 'package:flutter/foundation.dart';

enum MessageType { texte, image, fichier, audio, video }

class MessageContent {
  final MessageType type;
  final String? texte;
  final String? image;
  final String? fichier;
  final String? audio;
  final String? video;

  MessageContent({
    required this.type,
    this.texte,
    this.image,
    this.fichier,
    this.audio,
    this.video,
  });

  factory MessageContent.fromJson(Map<String, dynamic> json) {
    return MessageContent(
      type: MessageType.values.firstWhere(
        (e) => describeEnum(e) == json['type'],
        orElse: () => MessageType.texte,
      ),
      texte: json['texte'],
      image: json['image'],
      fichier: json['fichier'],
      audio: json['audio'],
      video: json['video'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': describeEnum(type),
      'texte': texte,
      'image': image,
      'fichier': fichier,
      'audio': audio,
      'video': video,
    };
  }
}

class User {
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
  final List<User> membres;
  User createur;

  Group({required this.id, required this.nom, required this.description, this.photo, required this.membres, required this.createur});

  factory Group.fromJson(Map<String, dynamic> json) {
    var membresFromJson = json['membres'] as List;
    List<User> membresList = membresFromJson.map((i) => User.fromJson(i)).toList();

    return Group(
      id: json['_id'],
      nom: json['nom'],
      createur: User.fromJson(json['createur']),
      description: json['description'],
      photo: json['photo'],
      membres: membresList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'description': description,
      'photo': photo,
      'membres': membres.map((user) => user.toJson()).toList(),
    };
  }
}

class LuPar {
  final String utilisateur;
  final DateTime dateLecture;

  LuPar({required this.utilisateur, required this.dateLecture});

  factory LuPar.fromJson(Map<String, dynamic> json) {
    return LuPar(
      utilisateur: json['utilisateur'],
      dateLecture: DateTime.parse(json['dateLecture']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'utilisateur': utilisateur,
      'dateLecture': dateLecture.toIso8601String(),
    };
  }
}

class GroupMessage {
  final String id;
  final MessageContent contenu;
  final User expediteur;
  final Group groupe;
  final bool notification;
  final List<LuPar>? luPar;
  final DateTime dateEnvoi;

  GroupMessage({
    required this.id,
    required this.contenu,
    required this.expediteur,
    required this.groupe,
    required this.notification,
    required this.luPar,
    required this.dateEnvoi,
      
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    var luParFromJson = json['luPar'] as List;
    List<LuPar> luParList = luParFromJson.map((i) => LuPar.fromJson(i)).toList();

    return GroupMessage(
      id: json['_id'],
      contenu: MessageContent.fromJson(json['contenu']),
      expediteur: User.fromJson(json['expediteur']),
      groupe: Group.fromJson(json['groupe']),
      notification: json['notification'],
      dateEnvoi: DateTime.parse(json['dateEnvoi']),
      luPar: luParList,
    );
  }
   bool isUserInGroup(String userId) {
    return groupe.membres.any((membre) => membre.id == userId);
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'contenu': contenu.toJson(),
      'expediteur': expediteur.toJson(),
      'groupe': groupe.toJson(),
      'notification': notification,
      'luPar': luPar!.map((lu) => lu.toJson()).toList(),
    };
  }
}

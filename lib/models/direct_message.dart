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

class DirectMessage {
  final String id;
  final MessageContent contenu;
  final User expediteur;
  final User destinataire;
  final DateTime dateEnvoi;
  final bool lu;
  final DateTime? dateLecture;

  DirectMessage({
    required this.id,
    required this.contenu,
    required this.expediteur,
    required this.destinataire,
    required this.dateEnvoi,
    required this.lu,
    this.dateLecture,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: json['_id'] ?? '',
      contenu: MessageContent.fromJson(json['contenu']),
      expediteur: User.fromJson(json['expediteur']),
      destinataire: User.fromJson(json['destinataire']),
      dateEnvoi: DateTime.parse(json['dateEnvoi']),
      lu: json['lu'] ?? false,
      dateLecture: json['dateLecture'] != null
          ? DateTime.parse(json['dateLecture'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'contenu': contenu.toJson(),
      'expediteur': expediteur.toJson(),
      'destinataire': destinataire.toJson(),
      'dateEnvoi': dateEnvoi.toIso8601String(),
      'lu': lu,
      'dateLecture': dateLecture?.toIso8601String(),
    };
  }
}

class User {
  final String id;
  final String nom;
  final String email;
  final String? photo;

  User({
    required this.id,
    required this.nom,
    required this.email,
    this.photo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      email: json['email'] ?? '',
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

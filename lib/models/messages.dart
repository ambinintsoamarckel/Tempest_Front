import 'dart:convert';
import 'package:http/http.dart' as http;

// Modèle de classe Contenu
class Contenu {
  final String type;
  final String? texte;
  final String? image;
  final String? fichier;
  final String? audio;
  final String? video;

  Contenu({
    required this.type,
    this.texte,
    this.image,
    this.fichier,
    this.audio,
    this.video,
  });

  factory Contenu.fromJson(Map<String, dynamic> json) {
    return Contenu(
      type: json['type'] ?? '',
      texte: json['texte'],
      image: json['image'],
      fichier: json['fichier'],
      audio: json['audio'],
      video: json['video'],
    );
  }
}

// Modèle de classe Contact
class Contact {
  final String id;
  final String type;
  final String nom;
  final String? photo;

  Contact({
    required this.id,
    required this.type,
    required this.nom,
    this.photo,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      nom: json['nom'] ?? '',
      photo: json['photo'],
    );
  }
}

// Modèle de classe DernierMessageUtilisateur
class DernierMessageUtilisateur {
  final String id;
  final Contenu contenu;
  final String expediteur;
  final bool lu;
  final DateTime dateEnvoi;
  final DateTime? dateLecture;

  DernierMessageUtilisateur({
    required this.id,
    required this.contenu,
    required this.expediteur,
    required this.lu,
    required this.dateEnvoi,
    this.dateLecture,
  });

  factory DernierMessageUtilisateur.fromJson(Map<String, dynamic> json) {
    return DernierMessageUtilisateur(
      id: json['_id'] ?? '',
      contenu: Contenu.fromJson(json['contenu'] ?? {}),
      expediteur: json['expediteur'] ?? '',
      lu: json['lu'] ?? false,
      dateEnvoi: DateTime.parse(json['dateEnvoi'] ?? DateTime.now().toString()),
      dateLecture: json['dateLecture'] != null ? DateTime.parse(json['dateLecture']) : null,
    );
  }
}

// Modèle de classe DernierMessageGroupe
class DernierMessageGroupe {
  final String id;
  final Contenu contenu;
  final String expediteur;
  final List<LectureUtilisateur> luPar;
  final DateTime dateEnvoi;
  final bool notification;

  DernierMessageGroupe({
    required this.id,
    required this.contenu,
    required this.expediteur,
    required this.luPar,
    required this.dateEnvoi,
    required this.notification,
  });

  factory DernierMessageGroupe.fromJson(Map<String, dynamic> json) {
    return DernierMessageGroupe(
      id: json['_id'] ?? '',
      contenu: Contenu.fromJson(json['contenu'] ?? {}),
      expediteur: json['expediteur'] ?? '',
      luPar: (json['luPar'] as List<dynamic>? ?? [])
          .map((entry) => LectureUtilisateur.fromJson(entry))
          .toList(),
      dateEnvoi: DateTime.parse(json['dateEnvoi'] ?? DateTime.now().toString()),
      notification: json['notification'] ?? false,
    );
  }
}

class LectureUtilisateur {
  final String utilisateurId;
  final DateTime? dateLecture;

  LectureUtilisateur({
    required this.utilisateurId,
    this.dateLecture,
  });

  factory LectureUtilisateur.fromJson(Map<String, dynamic> json) {
    return LectureUtilisateur(
      utilisateurId: json['utilisateur'] ?? '',
      dateLecture: json['dateLecture'] != null ? DateTime.parse(json['dateLecture']) : null,
    );
  }
}

// Modèle de classe Conversation
class Conversation {
  final Contact contact;
  final dynamic dernierMessage;

  Conversation({
    required this.contact,
    required this.dernierMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    Contact contact = Contact.fromJson(json['contact'] ?? {});
    dynamic dernierMessage;

    if (contact.type == 'utilisateur') {
      dernierMessage = DernierMessageUtilisateur.fromJson(json['dernierMessage'] ?? {});
    } else if (contact.type == 'groupe') {
      dernierMessage = DernierMessageGroupe.fromJson(json['dernierMessage'] ?? {});
    }


    return Conversation(
      contact: contact,
      dernierMessage: dernierMessage,
    );
  }
}

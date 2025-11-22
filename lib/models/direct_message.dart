// lib/models/direct_message.dart
import 'user.dart';
import 'message_content.dart'; // ✅ Importer au lieu de redéfinir

// ❌ SUPPRIMER tout le code de MessageType et MessageContent

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

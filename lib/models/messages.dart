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

class DernierMessage {
  final String id;
  final Contenu contenu;
  final List<dynamic> luPar;
  final DateTime dateEnvoi;
  final bool notification;

  DernierMessage({
    required this.id,
    required this.contenu,
    required this.luPar,
    required this.dateEnvoi,
    required this.notification,
  });

  factory DernierMessage.fromJson(Map<String, dynamic> json) {
    return DernierMessage(
      id: json['_id'] ?? '',
      contenu: Contenu.fromJson(json['contenu'] ?? {}),
      luPar: json['luPar'] ?? [],
      dateEnvoi: DateTime.parse(json['dateEnvoi'] ?? DateTime.now().toString()),
      notification: json['notification'] ?? false,
    );
  }
}

class Contenu {
  final String type;
  final String texte;

  Contenu({
    required this.type,
    required this.texte,
  });

  factory Contenu.fromJson(Map<String, dynamic> json) {
    return Contenu(
      type: json['type'] ?? '',
      texte: json['texte'] ?? '',
    );
  }
}

class Conversation {
  final Contact contact;
  final DernierMessage dernierMessage;

  Conversation({
    required this.contact,
    required this.dernierMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      contact: Contact.fromJson(json['contact'] ?? {}),
      dernierMessage: DernierMessage.fromJson(json['dernierMessage'] ?? {}),
    );
  }
}

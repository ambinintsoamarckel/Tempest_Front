class Contact {
  final String id;
  final String type;
  final String nom;
  final String? photo;
  final String presence;
  final bool story; // Booléen pour indiquer si l'utilisateur a des stories

  Contact({
    required this.id,
    required this.type,
    required this.nom,
    this.photo,
    required this.presence,
    required this.story,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      nom: json['nom'] ?? '',
      photo: json['photo'],
      presence: json['presence'] ?? 'inactif',
      story: json['story'] != null ? (json['story'] > 0) : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'nom': nom,
      'photo': photo,
      'presence': presence,
      'story': story,
    };
  }
}

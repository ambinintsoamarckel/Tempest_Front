class Contact {
  final String id;
  final String type;
  final String nom;
  final String? photo;
  final String presence;
  final List<String> story;

  Contact({
    required this.id,
    required this.type,
    required this.nom,
    this.photo,
    required this.presence,
    required this.story,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    List<String> storyFromJson = json['stories'] != null 
      ? (json['stories'] as List).map((item) => item as String).toList() 
      : [];

    return Contact(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      nom: json['nom'] ?? '',
      photo: json['photo'],
      presence: json['presence'] ?? 'inactif',
      story: storyFromJson,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'nom': nom,
      'photo': photo,
      'presence': presence,
      'stories': story,
    };
  }
}

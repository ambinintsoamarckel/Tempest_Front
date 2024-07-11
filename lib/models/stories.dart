class Story {
  final String id;
  final String utilisateur;
  final String typeContenu;
  final String? texte;
  final String? image;
  final String? video;
  final DateTime dateCreation;
  final DateTime dateExpiration;
  final List<String> vues;
  final bool active;

  Story({
    required this.id,
    required this.utilisateur,
    required this.typeContenu,
    this.texte,
    this.image,
    this.video,
    required this.dateCreation,
    required this.dateExpiration,
    required this.vues,
    required this.active,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['_id'],
      utilisateur: json['utilisateur'],
      typeContenu: json['contenu']['type'],
      texte: json['contenu']['texte'],
      image: json['contenu']['image'],
      video: json['contenu']['video'],
      dateCreation: DateTime.parse(json['dateCreation']),
      dateExpiration: DateTime.parse(json['dateExpiration']),
      vues: List<String>.from(json['vues']),
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'utilisateur': utilisateur,
      'contenu': {
        'type': typeContenu,
        'texte': texte,
        'image': image,
        'video': video,
      },
      'dateCreation': dateCreation.toIso8601String(),
      'dateExpiration': dateExpiration.toIso8601String(),
      'vues': vues,
      'active': active,
    };
  }
}

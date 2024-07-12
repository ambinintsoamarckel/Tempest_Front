class UserModel {
  final String uid;
  final String email;
  final String nom;
  late final String photo;
  final String presence;

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

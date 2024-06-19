class Contact {
  final String id;
  final String name;
  final String avatarUrl;
  final String phoneNumber;

  Contact({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.phoneNumber,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
    };
  }
}

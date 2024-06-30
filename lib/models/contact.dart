class Contact {
  final String id;
  final String name;
  final String? avatarUrl;

  Contact({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['_id'],
      name: json['nom'],
      avatarUrl: json['photo'],
    );
  }
}

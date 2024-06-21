class Story {
  final String id;
  final String title;
  final String imageUrl;
  final DateTime timestamp;

  Story({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.timestamp,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

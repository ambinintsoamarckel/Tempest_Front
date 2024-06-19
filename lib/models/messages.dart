class Conversation {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime timestamp;

  Conversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      name: json['name'],
      lastMessage: json['lastMessage'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastMessage': lastMessage,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

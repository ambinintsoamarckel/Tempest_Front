class Conversation {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime timestamp;
  final bool isGroup;

  Conversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.isGroup,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      name: json['name'],
      lastMessage: json['lastMessage'],
      timestamp: DateTime.parse(json['timestamp']),
      isGroup: json['isGroup'],
    );
  }
}
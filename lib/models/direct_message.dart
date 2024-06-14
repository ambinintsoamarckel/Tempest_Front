import 'dart:convert';

enum MessageType { text, file, image }

class DirectMessage {
  final String id;
  final String content;
  final String sender;
  final DateTime timestamp;
  final MessageType type;

  DirectMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    required this.type,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: json['id'],
      content: json['content'],
      sender: json['sender'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values[json['type']],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
    };
  }
}

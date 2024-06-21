import 'package:flutter/foundation.dart';

enum MessageType { text, file, image, audio }

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
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      sender: json['sender'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: MessageType.values.firstWhere(
            (e) => describeEnum(e) == json['type'],
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
      'type': describeEnum(type),
    };
  }
}

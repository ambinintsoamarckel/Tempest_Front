import 'package:flutter/foundation.dart';

enum MessageType { text, file, image, audio }

class GroupMessage {
  final String id;
  final String content;
  final String sender;
  final String groupId; // Nouvelle propriété pour l'ID du groupe
  final DateTime timestamp;
  final MessageType type;

  GroupMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.groupId,
    required this.timestamp,
    required this.type,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      sender: json['sender'] ?? '',
      groupId: json['groupId'] ?? '',
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
      'groupId': groupId,
      'timestamp': timestamp.toIso8601String(),
      'type': describeEnum(type),
    };
  }
}

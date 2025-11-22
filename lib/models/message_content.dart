// lib/models/message_content.dart
import 'package:flutter/foundation.dart';

enum MessageType { texte, image, fichier, audio, video }

class MessageContent {
  final MessageType type;
  final String? texte;
  final String? image;
  final String? fichier;
  final String? audio;
  final String? video;

  MessageContent({
    required this.type,
    this.texte,
    this.image,
    this.fichier,
    this.audio,
    this.video,
  });

  factory MessageContent.fromJson(Map<String, dynamic> json) {
    return MessageContent(
      type: MessageType.values.firstWhere(
        (e) => describeEnum(e) == json['type'],
        orElse: () => MessageType.texte,
      ),
      texte: json['texte'],
      image: json['image'],
      fichier: json['fichier'],
      audio: json['audio'],
      video: json['video'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': describeEnum(type),
      'texte': texte,
      'image': image,
      'fichier': fichier,
      'audio': audio,
      'video': video,
    };
  }
}

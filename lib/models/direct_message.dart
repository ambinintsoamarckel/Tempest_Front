enum MessageType { text, file, image }

class DirectMessage {
  final String content;
  final String sender;
  final DateTime timestamp;
  final MessageType type;

  DirectMessage({required this.content, required this.sender, required this.timestamp, required this.type});
}

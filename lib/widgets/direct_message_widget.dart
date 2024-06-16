import 'package:flutter/material.dart';
import 'dart:io';
import '../models/direct_message.dart';

class DirectMessageWidget extends StatelessWidget {
  final DirectMessage message;

  const DirectMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    Widget messageContent;
    if (message.type == MessageType.text) {
      messageContent = Text(
        message.content,
        style: TextStyle(
          color: message.sender == "User 1" ? Colors.blue : Colors.black,
        ),
      );
    } else if (message.type == MessageType.file) {
      messageContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.attach_file),
          Text(
            message.content.split('/').last,
            style: TextStyle(
              color: message.sender == "User 1" ? Colors.blue : Colors.black,
            ),
          ),
        ],
      );
    } else {
      messageContent = Image.file(
        File(message.content),
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.sender == "User 1" ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (message.sender != "User 1")
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(child: Text(message.sender[0])),
            ),
          Column(
            crossAxisAlignment: message.sender == "User 1" ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: <Widget>[
              Text(message.sender, style: Theme.of(context).textTheme.titleMedium),
              Container(
                margin: const EdgeInsets.only(top: 5.0),
                child: messageContent,
              ),
            ],
          ),
          if (message.sender == "User 1")
            Container(
              margin: const EdgeInsets.only(left: 16.0),
              child: CircleAvatar(child: Text(message.sender[0])),
            ),
        ],
      ),
    );
  }
}

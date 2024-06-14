import 'package:flutter/material.dart';
import '../models/group_message.dart';

class GroupMessageWidget extends StatelessWidget {
  final GroupMessage message;

  GroupMessageWidget({required this.message});

  @override
  Widget build(BuildContext context) {
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
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: message.sender == "User 1" ? Colors.blue : Colors.black,
                  ),
                ),
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

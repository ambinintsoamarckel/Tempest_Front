import 'package:flutter/material.dart';
import '../models/stories.dart';

class StoryWidget extends StatelessWidget {
  final Story story;

  const StoryWidget({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(story.imageUrl),
      title: Text(story.title),
      subtitle: Text(story.timestamp.toIso8601String()),
    );
  }
}

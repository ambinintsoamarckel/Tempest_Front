import 'package:flutter/material.dart';
import '../models/stories.dart';

class StoryWidget extends StatelessWidget {
  final Story story;

  const StoryWidget({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(story.user.name[0]),
        ),
        title: Text(story.user.name),
        subtitle: Text(story.creationDate.toIso8601String()),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryDetailScreen(story: story),
            ),
          );
        },
      ),
    );
  }
}

class StoryDetailScreen extends StatelessWidget {
  final Story story;

  const StoryDetailScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Story Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (story.type == 'image')
              Image.network(story.content)
            else if (story.type == 'video')
              // Add video player here
              Icon(Icons.videocam, size: 100)
            else if (story.type == 'texte')
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Text(
                  story.content,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(height: 16),
            Text(
              'Published at: ${story.creationDate.toIso8601String()}',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'Expires at: ${story.expirationDate.toIso8601String()}',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

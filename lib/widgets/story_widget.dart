import 'package:flutter/material.dart';
import '../models/stories.dart';

class StoryWidget extends StatelessWidget {
  final Story story;

  const StoryWidget({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeading(),
      title: _buildTitle(),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(story.user.name),
          Text(story.creationDate.toIso8601String()),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryDetailScreen(story: story),
          ),
        );
      },
    );
  }

  Widget _buildLeading() {
    if (story.type == 'image') {
      // Add a placeholder for image story
      return Icon(Icons.image, size: 50);
    } else if (story.type == 'video') {
      return Icon(Icons.videocam, size: 50); // Placeholder for video thumbnail
    } else {
      return Icon(Icons.text_fields, size: 50); // Placeholder for text story
    }
  }

  Widget _buildTitle() {
    if (story.type == 'texte') {
      return Text(story.content);
    } else if (story.type == 'image') {
      return Text('Image Story');
    } else if (story.type == 'video') {
      return Text('Video Story');
    } else {
      return Text('Unknown Story');
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (story.type == 'image')
              // Add an image placeholder
              Icon(Icons.image, size: 100)
            else if (story.type == 'video')
              // Add a video player here
              Icon(Icons.videocam, size: 100)
            else if (story.type == 'texte')
              Text(
                story.content,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 16),
            Text(
              'Published by: ${story.user.name}',
              style: TextStyle(color: Colors.grey),
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

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
      subtitle: Text(story.dateCreation.toIso8601String()),
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
    if (story.typeContenu == 'image' && story.image != null) {
      return Image.network(story.image!);
    } else if (story.typeContenu == 'video' && story.video != null) {
      return Icon(Icons.videocam, size: 50); // Placeholder for video thumbnail
    } else {
      return Icon(Icons.text_fields, size: 50); // Placeholder for text story
    }
  }

  Widget _buildTitle() {
    if (story.typeContenu == 'texte' && story.texte != null) {
      return Text(story.texte!);
    } else if (story.typeContenu == 'image' && story.image != null) {
      return Text('Image Story');
    } else if (story.typeContenu == 'video' && story.video != null) {
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
          children: [
            if (story.typeContenu == 'image' && story.image != null)
              Image.network(story.image!)
            else if (story.typeContenu == 'video' && story.video != null)
              // Add video player here
              Icon(Icons.videocam, size: 100)
            else if (story.typeContenu == 'texte' && story.texte != null)
              Text(
                story.texte!,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 16),
            Text(
              'Published at: ${story.dateCreation.toIso8601String()}',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'Expires at: ${story.dateExpiration.toIso8601String()}',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

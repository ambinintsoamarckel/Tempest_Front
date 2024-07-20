import 'package:flutter/material.dart';
import '../models/grouped_stories.dart';
import 'package:flutter/material.dart';

class StoryTile extends StatelessWidget {
  final GroupedStory story;

  const StoryTile({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryDetailScreen(story: story.stories[0]),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          image: DecorationImage(
            image: NetworkImage(story.stories[0].contenu.image ?? story.stories[0].contenu.video ?? ''),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8.0,
              left: 8.0,
              child: CircleAvatar(
                backgroundImage: story.utilisateur.photo != null? NetworkImage(story.utilisateur.photo!) : null,
                radius: 24.0,
              ),
            ),
            Positioned(
              bottom: 8.0,
              left: 8.0,
              child: Text(
                story.utilisateur.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
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
            if (story.contenu.type == StoryType.image)
              Image.network(story.contenu.image!)
            else if (story.contenu.type == StoryType.video)
              // Add video player here
              Icon(Icons.videocam, size: 100)
            else if (story.contenu.type == StoryType.texte)
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Text(
                  story.contenu.texte!,
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

import 'package:flutter/material.dart';
import '../models/grouped_stories.dart';
import 'dart:math';

class StoryTile extends StatelessWidget {
  final Story story;
  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.pink,
    Colors.cyan,
  ];

 StoryTile({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    final bool isTextStory = story.contenu.type == StoryType.texte;
    final Color backgroundColor = colors[Random().nextInt(colors.length)];

    return GestureDetector(
      /*onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryDetailScreen(story: story.stories[0]),
          ),
        );
      },*/
      child: Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: isTextStory ? backgroundColor : null,
          image: isTextStory
              ? null
              : DecorationImage(
                  image: NetworkImage(story.contenu.image ?? story.contenu.video ?? ''),
                  fit: BoxFit.cover,
                ),
        ),
        child: Stack(
          children: [
            if (isTextStory)
              Center(
                child: Text(
                  story.contenu.texte!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
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
        title: const Text('Story Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (story.contenu.type == StoryType.image)
              Image.network(story.contenu.image!)
            else if (story.contenu.type == StoryType.video)
              // Add video player here
              const Icon(Icons.videocam, size: 100)
            else if (story.contenu.type == StoryType.texte)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Text(
                  story.contenu.texte!,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Published at: ${story.creationDate.toIso8601String()}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              'Expires at: ${story.expirationDate.toIso8601String()}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/grouped_stories.dart';
import 'dart:math';

class StoryTile extends StatelessWidget {
  final GroupedStory story;
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
    final bool isTextStory = story.stories[0].contenu.type == StoryType.texte;
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
                  image: NetworkImage(story.stories[0].contenu.image ?? story.stories[0].contenu.video ?? ''),
                  fit: BoxFit.cover,
                ),
        ),
        child: Stack(
          children: [
            if (isTextStory)
              Center(
                child: Text(
                  story.stories[0].contenu.texte!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
              ),
            Positioned(
              top: 8.0,
              left: 8.0,
              child: CircleAvatar(
                radius: 24.0, // Taille de l'avatar
                backgroundImage: story.utilisateur.photo != null
                    ? NetworkImage(story.utilisateur.photo!)
                    : null,
                child: story.utilisateur.photo == null
                    ? const Icon(Icons.person, size: 24.0)
                    : null,
              ),
            ),
            Positioned(
              bottom: 8.0,
              left: 8.0,
              child: Text(
                story.utilisateur.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
            if (story.stories.length > 1)
              Positioned(
                top: 8.0,
                right: 8.0,
                child: Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${story.stories.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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

import 'package:flutter/material.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 10, // Remplacez par le nombre réel de stories
      itemBuilder: (context, index) {
        return Container(
          width: 100,
          margin: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 30,
                child: Icon(Icons.person),
              ),
              const SizedBox(height: 8),
              Text('Story ${index + 1}'), // Remplacez par le nom de la story
            ],
          ),
        );
      },
    );
  }
}

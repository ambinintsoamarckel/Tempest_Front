import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // Remplacez par le nombre réel de conversations
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text('Conversation ${index + 1}'), // Remplacez par le nom de la conversation
          subtitle: const Text('Dernier message'), // Remplacez par le dernier message
          onTap: () {
            // Ajoutez la navigation vers l'écran de conversation
          },
        );
      },
    );
  }
}

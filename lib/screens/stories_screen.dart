import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mini_social_network/services/story_service.dart';
import '../models/stories.dart';
import 'package:image_picker/image_picker.dart';

class StoryScreen extends StatefulWidget {
  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final StoryService _storyService = StoryService();
  late Future<List<Story>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _storiesFuture = _storyService.getStories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stories'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => StoryCreationDialog(storyService: _storyService),
              ).then((_) {
                setState(() {
                  _storiesFuture = _storyService.getStories();
                });
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Story>>(
        future: _storiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No stories available.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return StoryWidget(story: snapshot.data![index]);
              },
            );
          }
        },
      ),
    );
  }
}

class StoryCreationDialog extends StatefulWidget {
  final StoryService storyService;

  const StoryCreationDialog({super.key, required this.storyService});

  @override
  _StoryCreationDialogState createState() => _StoryCreationDialogState();
}

class _StoryCreationDialogState extends State<StoryCreationDialog> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedMedia;
  String _selectedType = 'texte';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Story'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: _selectedType,
            items: [
              DropdownMenuItem(value: 'texte', child: Text('Text')),
              DropdownMenuItem(value: 'image', child: Text('Image')),
              DropdownMenuItem(value: 'video', child: Text('Video')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          if (_selectedType == 'texte')
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: 'Enter your text'),
            ),
          if (_selectedType == 'image' || _selectedType == 'video')
            IconButton(
              icon: Icon(Icons.image),
              onPressed: () async {
                final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _selectedMedia = File(pickedFile.path);
                  });
                }
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Map<String, dynamic> storyData = {
              'type': _selectedType,
              if (_selectedType == 'texte') 'content': _textController.text,
              if (_selectedType == 'image' || _selectedType == 'video')
                'file': await MultipartFile.fromFile(_selectedMedia!.path),
            };
            await widget.storyService.createStory(storyData);
            Navigator.of(context).pop();
          },
          child: Text('Create'),
        ),
      ],
    );
  }
}

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
      return Icon(Icons.image, size: 50); // Placeholder for image story
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
              Icon(Icons.image, size: 100) // Add an image placeholder
            else if (story.type == 'video')
              Icon(Icons.videocam, size: 100) // Add a video player here
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

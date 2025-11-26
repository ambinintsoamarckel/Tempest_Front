import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_social_network/utils/screen_manager.dart';
import '../models/grouped_stories.dart';
import '../widgets/archive_widget.dart';
import '../services/story_service.dart';
import 'all_archive_screen.dart';

class StoryScreen extends StatefulWidget {
  final List<Story> stories;
  const StoryScreen({required this.stories, super.key});

  @override
  StoryScreenState createState() => StoryScreenState();
}

class StoryScreenState extends State<StoryScreen> {
  final List<Story> _stories = [];
  final StoryService _storyService = StoryService();
  final ScreenManager _screenManager = ScreenManager();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
    CurrentScreenManager.updateCurrentScreen('story');
    _screenManager.registerContactScreen(this);
  }

  Future<void> _loadStories() async {
    try {
      setState(() {
        _stories.addAll(widget.stories);
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load stories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onStorySelected(int index) {
    final storyIds = _stories.sublist(index).map((story) => story.id).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllStoriesScreen(
          initialIndex: 0,
          storyIds: storyIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
        ),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _onStorySelected(index),
            child: StoryTile(story: _stories[index]),
          );
        },
      ),
    );
  }
}

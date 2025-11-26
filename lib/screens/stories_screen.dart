import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_social_network/utils/screen_manager.dart';
import '../models/grouped_stories.dart';
import '../widgets/story_widget.dart';
import '../services/story_service.dart';
import 'all_screen.dart';
import 'creation_story.dart';

class StoryScreen extends StatefulWidget {
  final GlobalKey<StoryScreenState> storyScreenKey;

  const StoryScreen({required this.storyScreenKey})
      : super(key: storyScreenKey);

  @override
  StoryScreenState createState() => StoryScreenState();

  void reload() {
    final state = storyScreenKey.currentState;
    if (state != null) {
      state._reload();
    }
  }
}

class StoryScreenState extends State<StoryScreen> {
  final List<GroupedStory> _stories = [];
  final StoryService _storyService = StoryService();
  final ScreenManager _screenManager = ScreenManager();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
    _screenManager.registerStoryScreen(this);
    CurrentScreenManager.updateCurrentScreen('story');
  }

  Future<void> _loadStories() async {
    try {
      final stories = await _storyService.getStories();
      setState(() {
        _stories.addAll(stories);
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load stories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reload() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final stories = await _storyService.getStories();
      setState(() {
        _stories.clear();
        _stories.addAll(stories);
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load stories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createStory() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStoryScreen(onStoryCreated: _reload),
      ),
    );
  }

  void _onStorySelected(int index) {
    final storyIds = _stories
        .sublist(index)
        .expand((groupedStory) => groupedStory.stories)
        .map((story) => story.id)
        .toList();
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
        itemCount: _stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryTile(context);
          } else {
            return GestureDetector(
              onTap: () => _onStorySelected(index - 1),
              child: StoryTile(story: _stories[index - 1]),
            );
          }
        },
      ),
    );
  }

  Widget _buildAddStoryTile(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to story creation screen
        _createStory();
      },
      child: Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 50.0,
                color: Colors.black54,
              ),
              SizedBox(height: 8.0),
              Text(
                'Ajoutez à story',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

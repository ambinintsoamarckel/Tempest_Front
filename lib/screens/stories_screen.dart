import 'package:flutter/material.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import '../models/stories.dart';
import '../widgets/story_widget.dart';
import '../services/story_service.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final List<Story> _stories = [];
  final StoryService _storyService = StoryService(baseUrl: 'http://your_api_base_url_here');
  final CurrentScreenManager screenManager=CurrentScreenManager();

  @override
  void initState() {
    super.initState();
    _loadStories();
    screenManager.updateCurrentScreen('story');
  }

  Future<void> _loadStories() async {
    try {
      // Load stories from API and set state
    } catch (e) {
      print('Failed to load stories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stories')),
      body: ListView.builder(
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          return StoryWidget(story: _stories[index]);
        },
      ),
    );
  }
}

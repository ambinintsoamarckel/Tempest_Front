import 'package:flutter/material.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import '../models/stories.dart';
import '../widgets/story_widget.dart';
import '../services/story_service.dart';

class StoryScreen extends StatefulWidget {
  static final GlobalKey<_StoryScreenState> storyScreenKey = GlobalKey<_StoryScreenState>();

  StoryScreen() : super(key: storyScreenKey);

  @override
  _StoryScreenState createState() => _StoryScreenState();

  void reload() {
    final state = storyScreenKey.currentState;
    if (state != null) {
      state._reload();
    }
  }
}

class _StoryScreenState extends State<StoryScreen> {
  final List<Story> _stories = [];
  final StoryService _storyService = StoryService();
  final CurrentScreenManager screenManager = CurrentScreenManager();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
    screenManager.updateCurrentScreen('story');
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
    setState(() {
      _isLoading = true;
      _stories.clear();
    });
    await _loadStories();
  }

  Future<void> _createStory() async {
    // Logic to create a story
    // You might want to use a form to collect story data
    // And call _storyService.createStory() with the collected data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createStory, // Call function to create a story
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                return StoryWidget(story: _stories[index]);
              },
            ),
    );
  }
}

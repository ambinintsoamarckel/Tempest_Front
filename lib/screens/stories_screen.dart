import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import '../models/grouped_stories.dart';
import '../widgets/story_widget.dart';
import '../services/story_service.dart';
import 'all_screen.dart';
class StoryScreen extends StatefulWidget {
  final GlobalKey<StoryScreenState> storyScreenKey;

  const StoryScreen({required this.storyScreenKey}) : super(key: storyScreenKey);

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
    showDialog(
      context: context,
      builder: (context) {
        return StoryCreationDialog(onStoryCreated: _reload);
      },
    );
  }

  void _onStorySelected(int index) {
    final storyIds = _stories.sublist(index).expand((groupedStory) => groupedStory.stories).map((story) => story.id).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllStoriesScreen(
          initialIndex: index,
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

class StoryCreationDialog extends StatefulWidget {
  final VoidCallback onStoryCreated;

  const StoryCreationDialog({super.key, required this.onStoryCreated});

  @override
  _StoryCreationDialogState createState() => _StoryCreationDialogState();
}

class _StoryCreationDialogState extends State<StoryCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _storyText;
  File? _selectedMedia;
  String _mediaType = 'texte';
  final StoryService _storyService = StoryService();

  Future<void> _pickMedia(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedMedia = File(pickedFile.path);
        _mediaType = 'image';
      });
    }
  }

  Future<void> _submitStory() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      Map<String, dynamic> storyData = {
        'type': _mediaType,
        'texte': _storyText,
      };

      if (_selectedMedia != null) {
        try {
          await _storyService.createStoryFile(_selectedMedia!.path);
          widget.onStoryCreated();
          setState(() {
            _selectedMedia = null;
          });
          Navigator.of(context).pop();
        } catch (e) {
          print('Failed to create story: $e');
        }
      } else {
        try {
          await _storyService.createStory(storyData);
          widget.onStoryCreated();
          Navigator.of(context).pop();
        } catch (e) {
          print('Failed to create story: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Story'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Story Text'),
                maxLines: 3,
                validator: (value) {
                  if (_mediaType == 'texte' && (value == null || value.isEmpty)) {
                    return 'Text cannot be empty';
                  }
                  return null;
                },
                onSaved: (value) {
                  _storyText = value;
                },
              ),
              const SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: () => _pickMedia(ImageSource.gallery),
                child: const Text('Pick Image from Gallery'),
              ),
              const SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: () => _pickMedia(ImageSource.camera),
                child: const Text('Take a Photo'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitStory,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
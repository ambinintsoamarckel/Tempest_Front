import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    showDialog(
      context: context,
      builder: (context) {
        return StoryCreationDialog(onStoryCreated: _reload);
      },
    );
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
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                return StoryWidget(story: _stories[index]);
              },
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
        storyData['file'] = await MultipartFile.fromFile(_selectedMedia!.path);
      }

      try {
        await _storyService.createStory(storyData);
        widget.onStoryCreated();
        Navigator.of(context).pop();
      } catch (e) {
        print('Failed to create story: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Story'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Story Text'),
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
              SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: () => _pickMedia(ImageSource.gallery),
                child: Text('Pick Image from Gallery'),
              ),
              SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: () => _pickMedia(ImageSource.camera),
                child: Text('Take a Photo'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitStory,
          child: Text('Submit'),
        ),
      ],
    );
  }
}
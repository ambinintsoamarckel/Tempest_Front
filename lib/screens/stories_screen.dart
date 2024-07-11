import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/stories.dart';
import '../widgets/story_widget.dart';
import '../services/story_service.dart';
import 'dart:io';

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
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
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
    final result = await showDialog(
      context: context,
      builder: (context) => StoryCreationDialog(),
    );

    if (result != null) {
      try {
        await _storyService.createStory(result);
        _reload();
      } catch (e) {
        print('Failed to create story: $e');
      }
    }
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

class StoryCreationDialog extends StatefulWidget {
  @override
  _StoryCreationDialogState createState() => _StoryCreationDialogState();
}

class _StoryCreationDialogState extends State<StoryCreationDialog> {
  String _storyType = 'texte';
  final TextEditingController _textController = TextEditingController();
  File? _selectedMedia;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedMedia = File(pickedFile!.path);
    });
  }

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    setState(() {
      _selectedMedia = File(pickedFile!.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Story'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: _storyType,
            onChanged: (value) {
              setState(() {
                _storyType = value!;
                _selectedMedia = null;
              });
            },
            items: [
              DropdownMenuItem(
                value: 'texte',
                child: Text('Texte'),
              ),
              DropdownMenuItem(
                value: 'image',
                child: Text('Image'),
              ),
              DropdownMenuItem(
                value: 'video',
                child: Text('Video'),
              ),
            ],
          ),
          if (_storyType == 'texte')
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: 'Enter text'),
            ),
          if (_storyType == 'image')
            TextButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
          if (_storyType == 'video')
            TextButton(
              onPressed: _pickVideo,
              child: Text('Pick Video'),
            ),
          if (_selectedMedia != null) 
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Media selected: ${_selectedMedia!.path.split('/').last}'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_storyType == 'texte' && _textController.text.isNotEmpty) {
              Navigator.pop(context, {'type': 'texte', 'texte': _textController.text});
            } else if ((_storyType == 'image' || _storyType == 'video') && _selectedMedia != null) {
              Navigator.pop(context, {'type': _storyType, 'file': _selectedMedia});
            } else {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please fill in the required fields')),
              );
            }
          },
          child: Text('Create'),
        ),
      ],
    );
  }
}

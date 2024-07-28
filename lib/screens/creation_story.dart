import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/story_service.dart';
import 'texte_screen.dart';
import 'image_story_screen.dart';

class CreateStoryScreen extends StatefulWidget {
  final VoidCallback onStoryCreated;

  const CreateStoryScreen({super.key, required this.onStoryCreated});

  @override
  _CreateStoryScreenState createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
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

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImageStoryScreen(
            imageFile: _selectedMedia!,
            onStoryCreated: widget.onStoryCreated,
          ),
        ),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter à la story'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submitStory,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: [
                  GestureDetector(
                    onTap: () => _pickMedia(ImageSource.camera),
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 50.0,
                              color: Colors.black54,
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Appareil photo',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                     Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TextStoryScreen(
                            onStoryCreated: widget.onStoryCreated,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.text_fields,
                              size: 50.0,
                              color: Colors.black54,
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Texte',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _pickMedia(ImageSource.gallery),
              child: const Text('Choisir une image de la galerie'),
            ),
          ],
        ),
      ),
    );
  }
}

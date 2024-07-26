import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:mini_social_network/services/story_service.dart';

class TextStoryScreen extends StatefulWidget {
  final VoidCallback onStoryCreated;

  const TextStoryScreen({super.key, required this.onStoryCreated});

  @override
  _TextStoryScreenState createState() => _TextStoryScreenState();
}

class _TextStoryScreenState extends State<TextStoryScreen> {
  Color _backgroundColor = Colors.orangeAccent;
  String _storyText = "";
  Color _textColor = Colors.white;
  TextAlign _textAlign = TextAlign.center;
  final TextEditingController _textController = TextEditingController();
  final StoryService _storyService = StoryService();
  final ScreenshotController _screenshotController = ScreenshotController();

  void _pickTextColor() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choisir une couleur de texte'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _textColor,
              onColorChanged: (color) {
                setState(() {
                  _textColor = color;
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitStory() async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/story.png';
      _screenshotController.captureAndSave(
        directory.path,
        fileName: 'story.png',
        pixelRatio: 2.0,
      ).then((path) async {
        File imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await _storyService.createStoryFile(imagePath);
          widget.onStoryCreated();
          Navigator.of(context).pop();
        } else {
          print('Failed to create story: Image file does not exist');
        }
      }).catchError((error) {
        print('Failed to create story: $error');
      });
    } catch (e) {
      print('Failed to create story: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _submitStory,
            child: const Text(
              'GLAM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Screenshot(
              controller: _screenshotController,
              child: Container(
                color: _backgroundColor,
                width: double.infinity,
                height: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 26.0),
                child: Center(
                  child: TextFormField(
                    controller: _textController,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 24,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Appuyez pour écrire...',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: 24,
                      ),
                      border: InputBorder.none,
                    ),
                    textAlign: _textAlign,
                    maxLines: null,
                    onChanged: (value) {
                      setState(() {
                        _storyText = value;
                      });
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 100,
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.color_lens, color: Colors.white),
                    onPressed: _pickTextColor,
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_align_left, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _textAlign = TextAlign.left;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_align_center, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _textAlign = TextAlign.center;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_align_right, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _textAlign = TextAlign.right;
                      });
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: GestureDetector(
                onTap: _pickTextColor,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _backgroundColor,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: MediaQuery.of(context).size.width / 2 - 30,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      // Ajouter la fonctionnalité pour afficher la story précédente
                    },
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () {
                      // Ajouter la fonctionnalité pour afficher la story suivante
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

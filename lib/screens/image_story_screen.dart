import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:mini_social_network/services/story_service.dart';
import 'package:path_provider/path_provider.dart';

class ImageStoryScreen extends StatefulWidget {
  final File imageFile;
  final VoidCallback onStoryCreated;

  const ImageStoryScreen({
    super.key,
    required this.imageFile,
    required this.onStoryCreated,
  });

  @override
  _ImageStoryScreenState createState() => _ImageStoryScreenState();
}

class _ImageStoryScreenState extends State<ImageStoryScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final StoryService _storyService = StoryService();

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
          Navigator.popUntil(context, (route) => route.isFirst);
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
      backgroundColor: Colors.black,
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
              'PARTAGER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Screenshot(
          controller: _screenshotController,
          child: Image.file(widget.imageFile),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/stories.dart';
import '../services/story_service.dart';
import 'dart:math';

class AllStoriesScreen extends StatefulWidget {
  final List<String> storyIds;
  final int initialIndex;

  const AllStoriesScreen({
    super.key,
    required this.storyIds,
    required this.initialIndex,
  });

  @override
  _AllStoriesScreenState createState() => _AllStoriesScreenState();
}

class _AllStoriesScreenState extends State<AllStoriesScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final StoryService _storyService = StoryService();
  Story? _currentStory;
  bool _isLoading = true;

  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.pink,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadStory(widget.storyIds[_currentIndex]);
  }

  Future<void> _loadStory(String storyId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final story = await _storyService.getStoryById(storyId);
      setState(() {
        _currentStory = story;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_currentIndex < widget.storyIds.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadStory(widget.storyIds[_currentIndex]);
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadStory(widget.storyIds[_currentIndex]);
    }
  }

void _showViews() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return _currentStory != null
            ? ListView.builder(
                itemCount: _currentStory!.vues.length,
                itemBuilder: (context, index) {
                  final user = _currentStory!.vues[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.photo != '' ? NetworkImage(user.photo! ):null,
                    ),
                    title: Text(user.name),
                  );
                },
              )
            : Center(child: CircularProgressIndicator());
      },
    );
  
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_currentStory != null)
            PageView.builder(
              controller: _pageController,
              itemCount: widget.storyIds.length,
              itemBuilder: (context, index) {
                return Center(
                  child: buildStoryContent(_currentStory!),
                );
              },
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _loadStory(widget.storyIds[_currentIndex]);
              },
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (_currentIndex > 0)
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 24,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios),
                color: Colors.white,
                onPressed: _prevPage,
              ),
            ),
          if (_currentIndex < widget.storyIds.length - 1)
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 24,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_forward_ios),
                color: Colors.white,
                onPressed: _nextPage,
              ),
            ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            child: GestureDetector(
              onTap: _currentStory!=null && _currentStory!.vues.isNotEmpty ? _showViews: null,
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${_currentStory?.vues.length ?? 0} vues',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 60,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: _currentStory?.user.photo != '' ? NetworkImage(_currentStory?.user.photo ?? '') : null,
                ),
                SizedBox(width: 8),
                Text(
                  _currentStory?.user.name ?? '',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStoryContent(Story story) {
    final bool isTextStory = story.contenu.type == StoryType.texte;
    final Color backgroundColor = colors[Random().nextInt(colors.length)];

    return Container(
      decoration: BoxDecoration(
        color: isTextStory ? backgroundColor : null,
        image: !isTextStory
            ? DecorationImage(
                image: NetworkImage(story.contenu.image ?? story.contenu.video ?? ''),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Center(
        child: isTextStory
            ? Text(
                story.contenu.texte ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                ),
              )
            : null,
      ),
    );
  }
}

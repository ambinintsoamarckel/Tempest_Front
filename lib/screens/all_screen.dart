import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/stories.dart';
import '../models/grouped_stories.dart';
import '../services/story_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

class _AllStoriesScreenState extends State<AllStoriesScreen>
    with TickerProviderStateMixin {
  late PageController _userPageController;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;

  final StoryService _storyService = StoryService();
  final List<GroupedStory> _groupedStories = [];
  GroupedStory? _currentGroupedStory;
  Story? _currentStory;

  bool _isLoading = true;
  String? _currentUserId;
  bool _showControls = true;

  List<AnimationController> _progressControllers = [];
  late AnimationController _fadeController;

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _userPageController = PageController(initialPage: widget.initialIndex);
    _currentUserIndex = widget.initialIndex;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    _loadCurrentUser();
    _loadAllStories();

    // Cacher les contrôles après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
        _fadeController.reverse();
      }
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _userPageController.dispose();
    _fadeController.dispose();
    for (var controller in _progressControllers) {
      controller.dispose();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    String? user = await storage.read(key: 'user');
    user = user?.replaceAll('"', '').trim();
    if (mounted) {
      setState(() => _currentUserId = user);
    }
  }

  Future<void> _loadAllStories() async {
    setState(() => _isLoading = true);

    try {
      // Charger toutes les stories groupées
      for (String storyId in widget.storyIds) {
        final story = await _storyService.getStoryById(storyId);

        // Grouper par utilisateur
        final existingGroupIndex = _groupedStories.indexWhere(
          (group) => group.utilisateur.id == story!.user.id,
        );

        if (existingGroupIndex != -1) {
          _groupedStories[existingGroupIndex].stories.add(story!);
        } else {
          _groupedStories.add(
            GroupedStory(
              utilisateur: story!.user,
              stories: [story],
            ),
          );
        }
      }

      if (mounted && _groupedStories.isNotEmpty) {
        _currentGroupedStory = _groupedStories[_currentUserIndex];
        _currentStory = _currentGroupedStory!.stories[0];
        _initializeProgressControllers();
        _startStoryProgress();

        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading stories: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeProgressControllers() {
    // Disposer les anciens contrôleurs
    for (var controller in _progressControllers) {
      controller.dispose();
    }
    _progressControllers.clear();

    // Créer un contrôleur pour chaque story du groupe actuel
    if (_currentGroupedStory != null) {
      for (int i = 0; i < _currentGroupedStory!.stories.length; i++) {
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 5),
        );
        _progressControllers.add(controller);
      }
    }
  }

  void _startStoryProgress() {
    if (_currentStoryIndex >= _progressControllers.length) return;

    _progressControllers[_currentStoryIndex].reset();
    _progressControllers[_currentStoryIndex].forward().then((_) {
      if (mounted) _nextStory();
    });
  }

  void _pauseStoryProgress() {
    if (_currentStoryIndex < _progressControllers.length) {
      _progressControllers[_currentStoryIndex].stop();
    }
  }

  void _resumeStoryProgress() {
    if (_currentStoryIndex < _progressControllers.length) {
      _progressControllers[_currentStoryIndex].forward();
    }
  }

  void _nextStory() {
    if (_currentGroupedStory == null) return;

    if (_currentStoryIndex < _currentGroupedStory!.stories.length - 1) {
      // Story suivante du même utilisateur
      setState(() {
        _currentStoryIndex++;
        _currentStory = _currentGroupedStory!.stories[_currentStoryIndex];
      });
      _startStoryProgress();
    } else {
      // Utilisateur suivant
      _nextUser();
    }
  }

  void _prevStory() {
    if (_currentStoryIndex > 0) {
      // Story précédente du même utilisateur
      setState(() {
        _currentStoryIndex--;
        _currentStory = _currentGroupedStory!.stories[_currentStoryIndex];
      });
      _startStoryProgress();
    } else {
      // Utilisateur précédent
      _prevUser();
    }
  }

  void _nextUser() {
    if (_currentUserIndex < _groupedStories.length - 1) {
      _pauseStoryProgress();
      setState(() {
        _currentUserIndex++;
        _currentStoryIndex = 0;
        _currentGroupedStory = _groupedStories[_currentUserIndex];
        _currentStory = _currentGroupedStory!.stories[0];
      });
      _userPageController.animateToPage(
        _currentUserIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _initializeProgressControllers();
      _startStoryProgress();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevUser() {
    if (_currentUserIndex > 0) {
      _pauseStoryProgress();
      setState(() {
        _currentUserIndex--;
        _currentGroupedStory = _groupedStories[_currentUserIndex];
        _currentStoryIndex = _currentGroupedStory!.stories.length - 1;
        _currentStory = _currentGroupedStory!.stories[_currentStoryIndex];
      });
      _userPageController.animateToPage(
        _currentUserIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _initializeProgressControllers();
      // Marquer toutes les stories comme vues
      for (int i = 0; i < _currentStoryIndex; i++) {
        _progressControllers[i].value = 1.0;
      }
      _startStoryProgress();
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _fadeController.forward();
      _resumeStoryProgress();
    } else {
      _fadeController.reverse();
      _pauseStoryProgress();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    _pauseStoryProgress();
  }

  void _handleTapUp(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    if (tapPosition < screenWidth * 0.3) {
      // Tap à gauche = story/utilisateur précédent
      _prevStory();
    } else if (tapPosition > screenWidth * 0.7) {
      // Tap à droite = story/utilisateur suivant
      _nextStory();
    } else {
      // Tap au centre = toggle contrôles
      _toggleControls();
    }
  }

  void _showViews() {
    if (_currentStory == null || _currentStory!.vues.isEmpty) return;

    _pauseStoryProgress();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_rounded,
                        color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      '${_currentStory!.vues.length} vue${_currentStory!.vues.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _currentStory!.vues.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final user = _currentStory!.vues[index];
                    return ListTile(
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage:
                              user.photo != null && user.photo!.isNotEmpty
                                  ? NetworkImage(user.photo!)
                                  : null,
                          child: user.photo == null || user.photo!.isEmpty
                              ? const Icon(Icons.person, size: 22)
                              : null,
                        ),
                      ),
                      title: Text(
                        user.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => _resumeStoryProgress());
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.deepPurple;
    }
    try {
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.deepPurple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inMinutes}min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? _buildLoadingState()
          : GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              child: Stack(
                children: [
                  // Content
                  if (_currentStory != null)
                    PageView.builder(
                      controller: _userPageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _groupedStories.length,
                      itemBuilder: (context, index) {
                        return _buildStoryContent(_currentStory!);
                      },
                    ),

                  // Progress bars
                  _buildProgressBars(),

                  // Top bar with user info
                  _buildTopBar(),

                  // Bottom info
                  if (_currentStory != null) _buildBottomInfo(),

                  // Navigation hints
                  if (_showControls) _buildNavigationHints(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(40),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    if (_currentGroupedStory == null) return const SizedBox();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: List.generate(
            _currentGroupedStory!.stories.length,
            (index) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: index < _currentStoryIndex
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    : index == _currentStoryIndex &&
                            index < _progressControllers.length
                        ? AnimatedBuilder(
                            animation: _progressControllers[index],
                            builder: (context, child) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progressControllers[index].value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            },
                          )
                        : const SizedBox(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    if (_currentGroupedStory == null) return const SizedBox();

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeController,
        child: Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          child: Row(
            children: [
              // Close button
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  iconSize: 24,
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(width: 12),

              // User avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: _currentGroupedStory!.utilisateur.photo !=
                              null &&
                          _currentGroupedStory!.utilisateur.photo!.isNotEmpty
                      ? NetworkImage(_currentGroupedStory!.utilisateur.photo!)
                      : null,
                  child: _currentGroupedStory!.utilisateur.photo == null ||
                          _currentGroupedStory!.utilisateur.photo!.isEmpty
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
                ),
              ),

              const SizedBox(width: 10),

              // User name and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentGroupedStory!.utilisateur.nom,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_currentStory != null)
                      Text(
                        _formatDate(_currentStory!.creationDate),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // More options
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon:
                      const Icon(Icons.more_vert_rounded, color: Colors.white),
                  iconSize: 20,
                  onPressed: () {
                    // TODO: Show options
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Caption
                if (_currentStory!.contenu.caption != null &&
                    _currentStory!.contenu.caption!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _currentStory!.contenu.caption!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),

                // Views (si c'est notre story)
                if (_currentStory!.user.id == _currentUserId)
                  InkWell(
                    onTap: () {
                      _pauseStoryProgress();
                      _showViews();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${_currentStory!.vues.length} vue${_currentStory!.vues.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationHints() {
    return FadeTransition(
      opacity: _fadeController,
      child: Row(
        children: [
          // Left hint
          Expanded(
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white24,
                  size: 40,
                ),
              ),
            ),
          ),

          // Center (tap zone)
          Expanded(
            child: Container(),
          ),

          // Right hint
          Expanded(
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white24,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    final bool isTextStory = story.contenu.type == StoryType.texte;
    final bool isImageStory = story.contenu.type == StoryType.image;
    final bool isVideoStory = story.contenu.type == StoryType.video;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isTextStory) ...[
            _buildTextStoryBackground(story),
            _buildTextContent(story),
          ] else if (isImageStory && story.contenu.image != null) ...[
            _buildImageStory(story),
          ] else if (isVideoStory && story.contenu.video != null) ...[
            _buildVideoStory(story),
          ],
        ],
      ),
    );
  }

  Widget _buildTextStoryBackground(Story story) {
    final bgColor = _parseColor(story.contenu.backgroundColor);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bgColor,
            bgColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildTextContent(Story story) {
    final textColor = _parseColor(story.contenu.textColor);
    final fontSize = story.contenu.fontSize ?? 28.0;
    final fontWeight = story.contenu.fontWeight == 'bold'
        ? FontWeight.bold
        : FontWeight.normal;

    TextAlign textAlign = TextAlign.center;
    if (story.contenu.textAlign == 'left') {
      textAlign = TextAlign.left;
    } else if (story.contenu.textAlign == 'right') {
      textAlign = TextAlign.right;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          story.contenu.texte ?? '',
          textAlign: textAlign,
          style: TextStyle(
            color: textColor,
            fontWeight: fontWeight,
            fontSize: fontSize,
            letterSpacing: 0.5,
            height: 1.3,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageStory(Story story) {
    return Image.network(
      story.contenu.image!,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[900],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_rounded, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Image introuvable',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoStory(Story story) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Lecture vidéo à implémenter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

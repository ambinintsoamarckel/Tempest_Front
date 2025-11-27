import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/stories.dart';
import '../services/story_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AllArchiveScreen extends StatefulWidget {
  final List<String> storyIds;
  final int initialIndex;

  const AllArchiveScreen({
    super.key,
    required this.storyIds,
    required this.initialIndex,
  });

  @override
  _AllArchiveScreenState createState() => _AllArchiveScreenState();
}

class _AllArchiveScreenState extends State<AllArchiveScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  final StoryService _storyService = StoryService();
  Story? _currentStory;
  bool _isLoading = true;
  String? _currentUserId;
  bool _showControls = true;

  late AnimationController _progressController;
  late AnimationController _fadeController;

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Animation pour la barre de progression
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Animation pour les contrôles
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    _loadCurrentUser();
    _loadStory(widget.storyIds[_currentIndex]);
    _startProgressBar();

    // Cacher les contrôles après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
        _fadeController.reverse();
      }
    });

    // Mode plein écran
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startProgressBar() {
    _progressController.reset();
    _progressController.forward().then((_) {
      if (mounted) _nextPage();
    });
  }

  Future<void> _loadCurrentUser() async {
    String? user = await storage.read(key: 'user');
    user = user?.replaceAll('"', '').trim();
    if (mounted) {
      setState(() => _currentUserId = user);
    }
  }

  Future<void> _loadStory(String storyId) async {
    setState(() => _isLoading = true);

    try {
      final story = await _storyService.getArchivesById(storyId);
      if (mounted) {
        setState(() {
          _currentStory = story;
          _isLoading = false;
        });
        _startProgressBar();
      }
    } catch (e) {
      print('❌ Error loading story: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextPage() {
    if (_currentIndex < widget.storyIds.length - 1) {
      setState(() => _currentIndex++);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _loadStory(widget.storyIds[_currentIndex]);
    } else {
      Navigator.pop(context);
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _loadStory(widget.storyIds[_currentIndex]);
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _fadeController.forward();
      _progressController.forward();
    } else {
      _fadeController.reverse();
      _progressController.stop();
    }
  }

  void _showViews() {
    if (_currentStory == null || _currentStory!.vues.isEmpty) return;

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
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
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

              // List of views
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
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red),
              SizedBox(width: 12),
              Text('Supprimer l\'archive'),
            ],
          ),
          content: const Text(
            'Voulez-vous vraiment supprimer cette archive ? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implémenter la suppression
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
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

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inMinutes}min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            _prevPage();
          } else if (details.primaryVelocity! < 0) {
            _nextPage();
          }
        },
        child: Stack(
          children: [
            // Content
            if (_isLoading)
              _buildLoadingState()
            else if (_currentStory != null)
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.storyIds.length,
                itemBuilder: (context, index) {
                  return _buildStoryContent(_currentStory!);
                },
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _loadStory(widget.storyIds[_currentIndex]);
                },
              ),

            // Progress bars (en haut)
            _buildProgressBars(),

            // Top controls
            _buildTopControls(),

            // Bottom info
            if (_currentStory != null) _buildBottomInfo(),

            // Navigation buttons
            if (_showControls) _buildNavigationButtons(),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: List.generate(
            widget.storyIds.length,
            (index) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: index == _currentIndex
                    ? AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      )
                    : index < _currentIndex
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        : const SizedBox(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
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
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const Spacer(),

              // Date badge
              if (_currentStory != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(_currentStory!.creationDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(width: 8),

              // More options
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton<String>(
                  icon:
                      const Icon(Icons.more_vert_rounded, color: Colors.white),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
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
                // Caption (si disponible)
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

                // Views counter (si c'est l'utilisateur actuel)
                if (_currentStory!.user.id == _currentUserId)
                  InkWell(
                    onTap: _showViews,
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

  Widget _buildNavigationButtons() {
    return FadeTransition(
      opacity: _fadeController,
      child: Stack(
        children: [
          // Previous button
          if (_currentIndex > 0)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).size.height / 2 - 28,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white, size: 20),
                  onPressed: _prevPage,
                ),
              ),
            ),

          // Next button
          if (_currentIndex < widget.storyIds.length - 1)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height / 2 - 28,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 20),
                  onPressed: _nextPage,
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

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          if (isTextStory) ...[
            _buildTextStoryBackground(story),
          ] else if (isImageStory && story.contenu.image != null) ...[
            _buildImageStory(story),
          ] else if (isVideoStory && story.contenu.video != null) ...[
            _buildVideoStory(story),
          ],

          // Text content overlay (pour les stories texte)
          if (isTextStory) _buildTextContent(story),
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
    // TODO: Implémenter le lecteur vidéo
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

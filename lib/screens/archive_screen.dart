import 'package:flutter/material.dart';
import 'package:mini_social_network/utils/screen_manager.dart';
import '../models/stories.dart';
import '../services/story_service.dart';
import '../theme/app_theme.dart';
import 'all_archive_screen.dart';

class ArchiveStoryScreen extends StatefulWidget {
  final List<Story> stories;
  const ArchiveStoryScreen({required this.stories, super.key});

  @override
  ArchiveStoryScreenState createState() => ArchiveStoryScreenState();
}

class ArchiveStoryScreenState extends State<ArchiveStoryScreen> {
  final List<Story> _stories = [];
  final StoryService _storyService = StoryService();
  final ScreenManager _screenManager = ScreenManager();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStories();
    CurrentScreenManager.updateCurrentScreen('archive');
    _screenManager.registerStoryScreen(this);
  }

  @override
  void dispose() {
    print('🧹 ArchiveStoryScreen dispose called');
    super.dispose();
  }

  Future<void> _loadStories() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📥 [ArchiveScreen] Loading archived stories...');

      if (!mounted) return;

      setState(() {
        _stories.clear();
        _stories.addAll(widget.stories);
        _isLoading = false;
      });

      print('✅ [ArchiveScreen] Loaded ${_stories.length} archived stories');
    } catch (e) {
      print('❌ [ArchiveScreen] Failed to load stories: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger les archives';
      });
    }
  }

  Future<void> _reload() async {
    if (!mounted) return;
    await _loadStories();
  }

  void _onStorySelected(int index) {
    if (index >= _stories.length) return;

    final storyIds = _stories.sublist(index).map((story) => story.id).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllArchiveScreen(
          initialIndex: 0,
          storyIds: storyIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mes Archives',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }

    if (_stories.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return _buildArchiveGrid(isDark);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chargement des archives...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _errorMessage ?? 'Une erreur est survenue',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.2),
                  AppTheme.secondaryColor.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.archive_outlined,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune story archivée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos stories expirées apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveGrid(bool isDark) {
    return RefreshIndicator(
      onRefresh: _reload,
      color: AppTheme.primaryColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _onStorySelected(index),
            child: Hero(
              tag: 'archive_story_${_stories[index].id}',
              child: ArchiveStoryTile(story: _stories[index]),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// ARCHIVE STORY TILE - Version moderne et épurée
// ============================================================================

class ArchiveStoryTile extends StatelessWidget {
  final Story story;

  const ArchiveStoryTile({super.key, required this.story});

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.purple;
    }
    try {
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.purple;
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
    final bool isTextStory = story.contenu.type == StoryType.texte;
    final bool isImageStory = story.contenu.type == StoryType.image;
    final bool isVideoStory = story.contenu.type == StoryType.video;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            _buildBackground(isTextStory, isImageStory, isVideoStory),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Contenu texte
            if (isTextStory) _buildTextContent(),

            // Caption pour image/vidéo
            if ((isImageStory || isVideoStory) && story.contenu.caption != null)
              _buildCaption(),

            // Date en bas à gauche
            Positioned(
              bottom: 12,
              left: 12,
              right: 60,
              child: _buildDateLabel(),
            ),

            // Badge type en haut à droite
            Positioned(
              top: 12,
              right: 12,
              child: _buildStoryTypeBadge(isTextStory, isVideoStory),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(
      bool isTextStory, bool isImageStory, bool isVideoStory) {
    if (isTextStory) {
      final bgColor = _parseColor(story.contenu.backgroundColor);
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              bgColor,
              bgColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    } else if (isImageStory && story.contenu.image != null) {
      return Image.network(
        story.contenu.image!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          );
        },
      );
    } else if (isVideoStory && story.contenu.video != null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 60,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.7),
            AppTheme.secondaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    final textColor = _parseColor(story.contenu.textColor);
    final fontSize = story.contenu.fontSize ?? 18.0;
    final fontWeight = story.contenu.fontWeight == 'bold'
        ? FontWeight.bold
        : FontWeight.normal;

    TextAlign textAlign = TextAlign.center;
    if (story.contenu.textAlign == 'left') {
      textAlign = TextAlign.left;
    } else if (story.contenu.textAlign == 'right') {
      textAlign = TextAlign.right;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          story.contenu.texte ?? '',
          textAlign: textAlign,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontWeight: fontWeight,
            fontSize: fontSize,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaption() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 50,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          story.contenu.caption!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDateLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _formatDate(story.creationDate),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryTypeBadge(bool isTextStory, bool isVideoStory) {
    IconData icon;
    if (isTextStory) {
      icon = Icons.text_fields_rounded;
    } else if (isVideoStory) {
      icon = Icons.play_circle_filled_rounded;
    } else {
      icon = Icons.image_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

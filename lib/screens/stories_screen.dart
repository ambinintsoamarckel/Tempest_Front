import 'package:flutter/material.dart';
import 'package:mini_social_network/utils/screen_manager.dart';
import '../models/grouped_stories.dart';
import '../widgets/story_widget.dart';
import '../services/story_service.dart';
import '../theme/app_theme.dart';
import 'all_screen.dart';
import 'creation_story.dart';

class StoryScreen extends StatefulWidget {
  final GlobalKey<StoryScreenState> storyScreenKey;

  const StoryScreen({required this.storyScreenKey})
      : super(key: storyScreenKey);

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
  final ScreenManager _screenManager = ScreenManager();
  bool _isLoading = true;
  bool _isSilentReloading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStories();
    _screenManager.registerStoryScreen(this);
    CurrentScreenManager.updateCurrentScreen('story');
  }

  @override
  void dispose() {
    print('🧹 StoryScreen dispose called');
    super.dispose();
  }

  /// Chargement initial avec loader
  Future<void> _loadStories() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📥 [StoryScreen] Loading stories...');
      final stories = await _storyService.getStories();

      if (!mounted) return;

      // ✅ Filtrer les stories vides
      final validStories = stories.where((story) => story.hasStories).toList();

      setState(() {
        _stories.clear();
        _stories.addAll(validStories);
        _isLoading = false;
      });

      print('✅ [StoryScreen] Loaded ${validStories.length} valid stories');
    } catch (e) {
      print('❌ [StoryScreen] Failed to load stories: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger les stories';
      });
    }
  }

  /// Rechargement visible avec loader
  Future<void> _reload() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 [StoryScreen] Reloading stories...');
      final stories = await _storyService.getStories();

      if (!mounted) return;

      // ✅ Filtrer les stories vides
      final validStories = stories.where((story) => story.hasStories).toList();

      setState(() {
        _stories.clear();
        _stories.addAll(validStories);
        _isLoading = false;
      });

      print('✅ [StoryScreen] Reloaded ${validStories.length} valid stories');
    } catch (e) {
      print('❌ [StoryScreen] Failed to reload stories: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Échec du rechargement';
      });
    }
  }

  /// 🔇 Rechargement silencieux (sans loader visible)
  Future<void> silentReload() async {
    if (!mounted || _isSilentReloading) return;

    print('🔇 [StoryScreen] Silent reload started');

    setState(() {
      _isSilentReloading = true;
      _errorMessage = null;
    });

    try {
      final stories = await _storyService.getStories();

      if (!mounted) return;

      // ✅ Filtrer les stories vides
      final validStories = stories.where((story) => story.hasStories).toList();

      setState(() {
        _stories.clear();
        _stories.addAll(validStories);
        _isSilentReloading = false;
      });

      print(
          '✅ [StoryScreen] Silent reload completed with ${validStories.length} stories');
    } catch (e) {
      print('❌ [StoryScreen] Silent reload error: $e');

      if (!mounted) return;

      setState(() {
        _isSilentReloading = false;
        _errorMessage = 'Erreur de mise à jour';
      });
    }
  }

  Future<void> _createStory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStoryScreen(onStoryCreated: silentReload),
      ),
    );

    // Recharger si une story a été créée
    if (result == true && mounted) {
      silentReload();
    }
  }

  void _onStorySelected(int index) {
    if (index >= _stories.length) return;

    final storyIds = _stories
        .sublist(index)
        .expand((groupedStory) => groupedStory.stories)
        .map((story) => story.id)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllStoriesScreen(
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

    return _buildStoryGrid(isDark);
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
            'Chargement des stories...',
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
              Icons.auto_awesome_rounded,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune story disponible',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à partager une story !',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          _buildCreateButton(isDark, isLarge: true),
        ],
      ),
    );
  }

  Widget _buildStoryGrid(bool isDark) {
    return RefreshIndicator(
      onRefresh: silentReload,
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Indicateur de rechargement silencieux
          if (_isSilentReloading)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Mise à jour...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0) {
                    return _buildAddStoryTile(isDark);
                  } else {
                    return _buildStoryItem(index - 1, isDark);
                  }
                },
                childCount: _stories.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(int index, bool isDark) {
    // ✅ Vérifier l'index
    if (index >= _stories.length) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _onStorySelected(index),
      child: Hero(
        tag: 'story_${_stories[index].utilisateur.id}',
        child: StoryTile(story: _stories[index]),
      ),
    );
  }

  Widget _buildAddStoryTile(bool isDark) {
    return GestureDetector(
      onTap: _createStory,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.secondaryColor.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
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
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Créer une story',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(bool isDark, {bool isLarge = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _createStory,
          borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLarge ? 32 : 24,
              vertical: isLarge ? 16 : 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: isLarge ? 24 : 20,
                ),
                SizedBox(width: isLarge ? 12 : 8),
                Text(
                  'Créer une story',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isLarge ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

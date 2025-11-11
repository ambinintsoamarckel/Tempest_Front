import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stories.dart' as story_model;
import '../services/story_service.dart';
import '../models/grouped_stories.dart' as grouped;

// Provider pour le service de stories
final storyServiceProvider = Provider<StoryService>((ref) {
  return StoryService();
});

// State pour une story individuelle
class SingleStoryState {
  final Story? story;
  final bool isLoading;
  final String? error;

  SingleStoryState({
    this.story,
    this.isLoading = true,
    this.error,
  });

  SingleStoryState copyWith({
    Story? story,
    bool? isLoading,
    String? error,
  }) {
    return SingleStoryState(
      story: story ?? this.story,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier pour une story spécifique
class SingleStoryNotifier extends StateNotifier<SingleStoryState> {
  final StoryService _storyService;
  final String storyId;

  SingleStoryNotifier(this._storyService, this.storyId)
      : super(SingleStoryState(isLoading: true)) {
    loadStory();
  }

  Future<void> loadStory() async {
    state = state.copyWith(isLoading: true);
    try {
      final story = await _storyService.getStoryById(storyId);
      state = SingleStoryState(story: story, isLoading: false);
    } catch (e) {
      state = SingleStoryState(
        error: 'Failed to load story: $e',
        isLoading: false,
      );
    }
  }
}

// Provider pour une story spécifique (avec family pour passer le storyId)
final singleStoryProvider =
    StateNotifierProvider.family<SingleStoryNotifier, SingleStoryState, String>(
  (ref, storyId) {
    final service = ref.watch(storyServiceProvider);
    return SingleStoryNotifier(service, storyId);
  },
);

// State pour la navigation entre stories
class AllStoriesState {
  final List<String> storyIds;
  final int currentIndex;
  final Story? currentStory;
  final bool isLoading;

  AllStoriesState({
    required this.storyIds,
    this.currentIndex = 0,
    this.currentStory,
    this.isLoading = true,
  });

  AllStoriesState copyWith({
    List<String>? storyIds,
    int? currentIndex,
    Story? currentStory,
    bool? isLoading,
  }) {
    return AllStoriesState(
      storyIds: storyIds ?? this.storyIds,
      currentIndex: currentIndex ?? this.currentIndex,
      currentStory: currentStory ?? this.currentStory,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  String get currentStoryId => storyIds[currentIndex];
}

// Notifier pour la navigation entre stories
class AllStoriesNotifier extends StateNotifier<AllStoriesState> {
  final StoryService _storyService;

  AllStoriesNotifier(
    this._storyService,
    List<String> storyIds,
    int initialIndex,
  ) : super(AllStoriesState(storyIds: storyIds, currentIndex: initialIndex)) {
    _loadCurrentStory();
  }

  Future<void> _loadCurrentStory() async {
    state = state.copyWith(isLoading: true);
    try {
      final story = await _storyService.getStoryById(state.currentStoryId);
      state = AllStoriesState(
        storyIds: state.storyIds,
        currentIndex: state.currentIndex,
        currentStory: story,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void nextPage() {
    if (state.currentIndex < state.storyIds.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
      _loadCurrentStory();
    }
  }

  void previousPage() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
      _loadCurrentStory();
    }
  }

  void onPageChanged(int index) {
    state = state.copyWith(currentIndex: index);
    _loadCurrentStory();
  }
}

// Provider pour la navigation entre stories
final allStoriesProvider = StateNotifierProvider.family<AllStoriesNotifier,
    AllStoriesState, ({List<String> storyIds, int initialIndex})>(
  (ref, args) {
    final service = ref.watch(storyServiceProvider);
    return AllStoriesNotifier(service, args.storyIds, args.initialIndex);
  },
);

// State pour la liste des stories
class StoriesListState {
  final List<grouped.GroupedStory> stories;
  final bool isLoading;
  final String? error;

  StoriesListState({
    this.stories = const [],
    this.isLoading = true,
    this.error,
  });

  StoriesListState copyWith({
    List<grouped.GroupedStory>? stories,
    bool? isLoading,
    String? error,
  }) {
    return StoriesListState(
      stories: stories ?? this.stories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier pour la liste des stories
class StoriesListNotifier extends StateNotifier<StoriesListState> {
  final StoryService _storyService;

  StoriesListNotifier(this._storyService) : super(StoriesListState()) {
    loadStories();
  }

  Future<void> loadStories() async {
    state = state.copyWith(isLoading: true);
    try {
      final stories = await _storyService.getStories();
      state = state.copyWith(stories: stories, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load stories: $e', isLoading: false);
    }
  }

  Future<void> reload() async {
    await loadStories();
  }
}

// Provider pour la liste des stories
final storiesListProvider =
    StateNotifierProvider<StoriesListNotifier, StoriesListState>((ref) {
  final service = ref.watch(storyServiceProvider);
  return StoriesListNotifier(service);
});

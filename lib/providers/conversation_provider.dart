import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/messages.dart';
import '../services/list_message_service.dart';

// Provider pour le service de messages
final conversationServiceProvider = Provider<MessageService>((ref) {
  return MessageService();
});

// State pour la liste des conversations
class ConversationListState {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? error;

  ConversationListState({
    this.conversations = const [],
    this.isLoading = true,
    this.error,
  });

  ConversationListState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationListState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier pour la liste des conversations
class ConversationListNotifier extends StateNotifier<ConversationListState> {
  final MessageService _messageService;

  ConversationListNotifier(this._messageService) : super(ConversationListState()) {
    loadConversations();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true);
    try {
      final conversations = await _messageService.getConversationsWithContact();
      state = state.copyWith(conversations: conversations, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load conversations: $e', isLoading: false);
    }
  }

  Future<void> reload() async {
    await loadConversations();
  }
}

// Provider pour la liste des conversations
final conversationListProvider =
    StateNotifierProvider<ConversationListNotifier, ConversationListState>((ref) {
  final service = ref.watch(conversationServiceProvider);
  return ConversationListNotifier(service);
});

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/direct_message.dart';
import '../services/discu_message_service.dart';

// Provider pour le service de messages
final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService();
});

// State pour les messages d'une conversation
class MessagesState {
  final List<DirectMessage> messages;
  final User? contact;
  final bool isLoading;
  final String? error;

  MessagesState({
    this.messages = const [],
    this.contact,
    this.isLoading = true,
    this.error,
  });

  MessagesState copyWith({
    List<DirectMessage>? messages,
    User? contact,
    bool? isLoading,
    String? error,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      contact: contact ?? this.contact,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier pour gérer les messages d'une conversation
class MessagesNotifier extends StateNotifier<MessagesState> {
  final MessageService _messageService;
  final String conversationId;

  MessagesNotifier(this._messageService, this.conversationId)
      : super(MessagesState(isLoading: true)) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true);
    try {
      final messages =
          await _messageService.receiveMessagesFromUrl(conversationId);

      User? contact;
      if (messages.isNotEmpty) {
        contact = messages[0].expediteur.id == conversationId
            ? messages[0].expediteur
            : messages[0].destinataire;
      } else {
        contact = User(
            id: conversationId,
            nom: "Nouveau contact",
            email: "email@example.com",
            photo: null);
      }

      state = state.copyWith(
        messages: messages,
        contact: contact,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load messages: $e',
        isLoading: false,
      );
    }
  }

  Future<void> reload() async {
    await loadMessages();
  }

  Future<bool> sendMessage(String text) async {
    try {
      final result =
          await _messageService.createMessage(conversationId, {"texte": text});
      if (result != null) {
        await reload();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to send message: $e');
      return false;
    }
  }

  Future<bool> sendFile(String filePath) async {
    try {
      await _messageService.sendFileToPerson(conversationId, filePath);
      await reload();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to send file: $e');
      return false;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _messageService.deleteMessage(messageId);
      await reload();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete message: $e');
    }
  }
}

// Provider pour les messages d'une conversation
final messagesProvider =
    StateNotifierProvider.family<MessagesNotifier, MessagesState, String>(
  (ref, conversationId) {
    final service = ref.watch(messageServiceProvider);
    return MessagesNotifier(service, conversationId);
  },
);

// State pour le preview de fichier
class FilePreviewState {
  final File? file;
  final String? type; // 'image', 'audio', 'file'

  FilePreviewState({this.file, this.type});

  FilePreviewState copyWith({
    File? file,
    String? type,
  }) {
    return FilePreviewState(
      file: file ?? this.file,
      type: type ?? this.type,
    );
  }

  bool get hasPreview => file != null;

  void clear() {}
}

// Provider pour le preview de fichier
final filePreviewProvider =
    StateProvider.family<FilePreviewState?, String>((ref, conversationId) {
  return null;
});

// Provider pour l'état d'enregistrement audio
final isRecordingProvider =
    StateProvider.family<bool, String>((ref, conversationId) {
  return false;
});

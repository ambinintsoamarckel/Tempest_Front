import 'package:flutter/material.dart';

/// Gestionnaire pour tracker l'écran actuel (SIMPLE)
class CurrentScreenManager {
  static String? currentScreen;

  /// Met à jour l'écran actuel - appelé par chaque écran
  static void updateCurrentScreen(String? currentPath) {
    if (currentPath != null) {
      currentScreen = currentPath;
      print('📍 Current screen: $currentPath');
    }
  }

  /// Vérifie si on est sur un écran spécifique
  static bool isOnScreen(String screenName) {
    return currentScreen == screenName;
  }

  /// Nettoie l'écran actuel
  static void clear() {
    currentScreen = null;
    print('🧹 CurrentScreenManager cleared');
  }
}

/// Gestionnaire global pour accéder aux états des écrans via Singleton
class ScreenManager {
  // Instance singleton
  static final ScreenManager _instance = ScreenManager._internal();
  factory ScreenManager() => _instance;
  ScreenManager._internal();

  // États des écrans - stockés comme dynamic pour éviter les imports circulaires
  dynamic _contactScreenState;
  dynamic _conversationListState;
  dynamic _storyScreenState;
  dynamic _directChatScreenState;
  dynamic _groupChatScreenState;

  // ========== ENREGISTREMENT DES STATES ==========

  /// Enregistre le state du ContactScreen
  void registerContactScreen(dynamic state) {
    _contactScreenState = state;
    print('🔑 ContactScreen state registered');
  }

  /// Enregistre le state du ConversationListScreen
  void registerConversationList(dynamic state) {
    _conversationListState = state;
    print('🔑 ConversationList state registered');
  }

  /// Enregistre le state du StoryScreen
  void registerStoryScreen(dynamic state) {
    _storyScreenState = state;
    print('🔑 StoryScreen state registered');
  }

  /// Enregistre le state du DirectChatScreen
  void registerDirectChatScreen(dynamic state) {
    _directChatScreenState = state;
    print('🔑 DirectChatScreen state registered');
  }

  /// Enregistre le state du GroupChatScreen
  void registerGroupChatScreen(dynamic state) {
    _groupChatScreenState = state;
    print('🔑 GroupChatScreen state registered');
  }

  // ========== DÉSENREGISTREMENT ==========

  void unregisterContactScreen() {
    _contactScreenState = null;
    print('🧹 ContactScreen state unregistered');
  }

  void unregisterConversationList() {
    _conversationListState = null;
    print('🧹 ConversationList state unregistered');
  }

  void unregisterStoryScreen() {
    _storyScreenState = null;
    print('🧹 StoryScreen state unregistered');
  }

  void unregisterDirectChatScreen() {
    _directChatScreenState = null;
    print('🧹 DirectChatScreen state unregistered');
  }

  void unregisterGroupChatScreen() {
    _groupChatScreenState = null;
    print('🧹 GroupChatScreen state unregistered');
  }

  // ========== MÉTHODES DE RELOAD ==========

  /// Recharge l'écran des contacts
  void reloadContactScreen() {
    try {
      if (_contactScreenState?.mounted == true) {
        _contactScreenState.widget.reload();
        print('✅ Contact screen reloaded');
      } else {
        print('⚠️ ContactScreen state not available');
      }
    } catch (e) {
      print('❌ Erreur reload contact screen: $e');
    }
  }

  /// Recharge la liste des conversations
  void reloadConversationList() {
    try {
      if (_conversationListState?.mounted == true) {
        _conversationListState.widget.reload();
        print('✅ Conversation list reloaded');
      } else {
        print('⚠️ ConversationList state not available');
      }
    } catch (e) {
      print('❌ Erreur reload conversation list: $e');
    }
  }

  /// Recharge l'écran des stories
  void reloadStoryScreen() {
    try {
      if (_storyScreenState?.mounted == true) {
        _storyScreenState.widget.reload();
        print('✅ Story screen reloaded');
      } else {
        print('⚠️ StoryScreen state not available');
      }
    } catch (e) {
      print('❌ Erreur reload story screen: $e');
    }
  }

  /// Recharge le chat direct avec un contact spécifique
  void reloadDirectChat(String contactId) {
    try {
      if (_directChatScreenState?.mounted == true) {
        if (_directChatScreenState.widget.contactId == contactId) {
          _directChatScreenState.widget.reloadFromSocket();
          print('✅ Direct chat reloaded for contact: $contactId');
        } else {
          print(
              '⚠️ DirectChat contactId mismatch: ${_directChatScreenState.widget.contactId} != $contactId');
        }
      } else {
        print('⚠️ DirectChatScreen state not available');
      }
    } catch (e) {
      print('❌ Erreur reload direct chat: $e');
    }
  }

  /// Recharge le chat de groupe avec un groupe spécifique
  void reloadGroupChat(String groupId) {
    try {
      if (_groupChatScreenState?.mounted == true) {
        if (_groupChatScreenState.widget.groupId == groupId) {
          _groupChatScreenState.widget.reload();
          print('✅ Group chat reloaded for group: $groupId');
        } else {
          print(
              '⚠️ GroupChat groupId mismatch: ${_groupChatScreenState.widget.groupId} != $groupId');
        }
      } else {
        print('⚠️ GroupChatScreen state not available');
      }
    } catch (e) {
      print('❌ Erreur reload group chat: $e');
    }
  }

  // ========== NETTOYAGE ==========

  /// Nettoie tous les states (appelé au logout)
  void clearAll() {
    _contactScreenState = null;
    _conversationListState = null;
    _storyScreenState = null;
    _directChatScreenState = null;
    _groupChatScreenState = null;
    CurrentScreenManager.clear();
    print('🧹 ScreenManager cleared');
  }
}

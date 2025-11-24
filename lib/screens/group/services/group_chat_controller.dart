// lib/screens/group/services/group_chat_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mini_social_network/models/group_message.dart';
import 'package:mini_social_network/models/user.dart';
import 'package:mini_social_network/models/message_content.dart';
import 'package:mini_social_network/services/discu_group_service.dart';
import 'package:mini_social_network/screens/chat/services/base_chat_controller.dart';

class GroupMessageWrapper {
  final GroupMessage message;
  final bool isSending;
  final bool sendFailed;
  final String? tempId;

  GroupMessageWrapper({
    required this.message,
    this.isSending = false,
    this.sendFailed = false,
    this.tempId,
  });
}

class GroupChatController
    extends BaseChatController<GroupMessage, GroupMessageWrapper> {
  final String groupId;
  final GroupChatService _messageService = GroupChatService();

  Group? _currentGroup;

  GroupChatController(this.groupId);

  // ========== Getter spécifique au groupe ==========
  Group? get currentGroup => _currentGroup;

  // ========== Implémentation des méthodes abstraites ==========

  @override
  Future<List<GroupMessage>> fetchMessagesFromService() async {
    final messages = await _messageService.receiveGroupMessages(groupId);

    // Charger le groupe depuis le premier message
    if (messages.isNotEmpty) {
      _currentGroup = messages.first.groupe;
      print('✅ [GroupChatController] Groupe chargé: ${_currentGroup!.nom}');
    }

    return messages;
  }

  @override
  GroupMessageWrapper wrapMessage(
    GroupMessage message, {
    bool isSending = false,
    bool sendFailed = false,
    String? tempId,
  }) {
    return GroupMessageWrapper(
      message: message,
      isSending: isSending,
      sendFailed: sendFailed,
      tempId: tempId,
    );
  }

  @override
  GroupMessage createTempMessage({
    required String tempId,
    required MessageContent content,
    required User expediteur,
  }) {
    if (_currentGroup == null) {
      throw Exception('Group not loaded yet');
    }

    return GroupMessage(
      id: tempId,
      expediteur: expediteur,
      groupe: _currentGroup!,
      contenu: content,
      dateEnvoi: DateTime.now(),
      notification: false,
      luPar: [],
    );
  }

  @override
  Future<bool> sendTextToServer(Map<String, dynamic> data) async {
    try {
      final result = await _messageService.createMessage(groupId, data);
      return result ?? false;
    } catch (e) {
      print('❌ [GroupChatController] Erreur sendTextToServer: $e');
      return false;
    }
  }

  @override
  Future<bool> sendFileToServer(String filePath) async {
    try {
      final result = await _messageService.sendFileToGroup(groupId, filePath);
      return result ?? false;
    } catch (e) {
      print('❌ [GroupChatController] Erreur sendFileToServer: $e');
      return false;
    }
  }

  @override
  Future<void> deleteMessageFromServer(String messageId) async {
    await _messageService.deleteMessage(messageId);
  }

  @override
  String getRecipientId() => groupId;

  // ========== Méthodes utilitaires pour accéder au wrapper ==========

  @override
  String? getTempId(GroupMessageWrapper wrapper) => wrapper.tempId;

  @override
  bool isMessageSending(GroupMessageWrapper wrapper) => wrapper.isSending;

  @override
  GroupMessage getMessageFromWrapper(GroupMessageWrapper wrapper) =>
      wrapper.message;

  @override
  String getMessageId(GroupMessageWrapper wrapper) => wrapper.message.id;
}

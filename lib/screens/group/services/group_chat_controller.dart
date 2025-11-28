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

  Group? get currentGroup => _currentGroup;

  @override
  Future<List<GroupMessage>> fetchMessagesFromService() async {
    print('📡 [GroupChatController] Fetch des messages pour groupId: $groupId');
    final messages = await _messageService.receiveGroupMessages(groupId);

    // ✅ CRITICAL: Mettre à jour le groupe à chaque fetch
    if (messages.isNotEmpty) {
      final newGroup = messages.first.groupe;

      // Log des changements pour debug
      if (_currentGroup != null) {
        if (_currentGroup!.nom != newGroup.nom) {
          print(
              '🔄 [GroupChatController] Nom du groupe changé: "${_currentGroup!.nom}" → "${newGroup.nom}"');
        }
        if (_currentGroup!.photo != newGroup.photo) {
          print('🔄 [GroupChatController] Photo du groupe changée');
        }
        if (_currentGroup!.membres.length != newGroup.membres.length) {
          print(
              '🔄 [GroupChatController] Nombre de membres changé: ${_currentGroup!.membres.length} → ${newGroup.membres.length}');
        }
      }

      _currentGroup = newGroup;
      print('✅ [GroupChatController] Groupe mis à jour: ${_currentGroup!.nom}');
    } else {
      print(
          '⚠️ [GroupChatController] Aucun message reçu, groupe non mis à jour');
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

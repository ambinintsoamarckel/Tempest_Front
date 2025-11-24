// lib/screens/direct/services/direct_chat_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mini_social_network/models/direct_message.dart';
import 'package:mini_social_network/models/user.dart';
import 'package:mini_social_network/models/message_content.dart';
import 'package:mini_social_network/services/discu_message_service.dart';
import 'package:mini_social_network/screens/chat/services/base_chat_controller.dart';


class MessageWrapper {
  final DirectMessage message;
  final bool isSending;
  final bool sendFailed;
  final String? tempId;

  MessageWrapper({
    required this.message,
    this.isSending = false,
    this.sendFailed = false,
    this.tempId,
  });
}

class DirectChatController
    extends BaseChatController<DirectMessage, MessageWrapper> {
  final String contactId;
  final MessageService messageService = MessageService();

  DirectChatController(this.contactId);

  // ========== Implémentation des méthodes abstraites ==========

  @override
  Future<List<DirectMessage>> fetchMessagesFromService() async {
    return await messageService.receiveMessagesFromUrl(contactId);
  }

  @override
  MessageWrapper wrapMessage(
    DirectMessage message, {
    bool isSending = false,
    bool sendFailed = false,
    String? tempId,
  }) {
    return MessageWrapper(
      message: message,
      isSending: isSending,
      sendFailed: sendFailed,
      tempId: tempId,
    );
  }

  @override
  DirectMessage createTempMessage({
    required String tempId,
    required MessageContent content,
    required User expediteur,
  }) {
    return DirectMessage(
      id: tempId,
      expediteur: expediteur,
      destinataire: User(
        id: contactId,
        nom: '',
        email: '',
        photo: null,
      ),
      contenu: content,
      dateEnvoi: DateTime.now(),
      lu: false,
    );
  }

  @override
  Future<bool> sendTextToServer(Map<String, dynamic> data) async {
    try {
      await messageService.createMessage(contactId, data);
      return true;
    } catch (e) {
      print('❌ [DirectChatController] Erreur sendTextToServer: $e');
      return false;
    }
  }

  @override
  Future<bool> sendFileToServer(String filePath) async {
    try {
      final success =
          await messageService.sendFileToPerson(contactId, filePath);
      return success;
    } catch (e) {
      print('❌ [DirectChatController] Erreur sendFileToServer: $e');
      return false;
    }
  }

  @override
  Future<void> deleteMessageFromServer(String messageId) async {
    await messageService.deleteMessage(messageId);
  }

  @override
  String getRecipientId() => contactId;

  // ========== Méthodes utilitaires pour accéder au wrapper ==========

  @override
  String? getTempId(MessageWrapper wrapper) => wrapper.tempId;

  @override
  bool isMessageSending(MessageWrapper wrapper) => wrapper.isSending;

  @override
  DirectMessage getMessageFromWrapper(MessageWrapper wrapper) =>
      wrapper.message;

  @override
  String getMessageId(MessageWrapper wrapper) => wrapper.message.id;
}

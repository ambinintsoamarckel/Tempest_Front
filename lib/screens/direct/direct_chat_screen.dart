// lib/screens/direct/direct_chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mini_social_network/models/direct_message.dart';
import 'package:mini_social_network/models/user.dart';
import 'package:mini_social_network/widgets/messages/direct_message_widget.dart';
import 'package:mini_social_network/widgets/voice_recording_widget.dart';
import 'package:mini_social_network/screens/ctt_screen.dart';
import 'package:mini_social_network/screens/direct/widgets/direct_input_area.dart';
import 'package:mini_social_network/screens/direct/widgets/file_preview.dart';
import 'package:mini_social_network/screens/direct/widgets/message_date_badge.dart';
import 'package:mini_social_network/screens/direct/services/direct_chat_controller.dart';
import 'widgets/direct_chat_app_bar.dart';

class DirectChatScreen extends StatefulWidget {
  final String contactId;
  static final GlobalKey<_DirectChatScreenState> directChatScreenKey =
      GlobalKey<_DirectChatScreenState>();

  DirectChatScreen({required this.contactId}) : super(key: directChatScreenKey);
  @override
  _DirectChatScreenState createState() => _DirectChatScreenState();

  void reload() {
    final state = directChatScreenKey.currentState;
    state?._reload();
  }

  void reloadFromSocket() {
    final state = directChatScreenKey.currentState;
    print('Socket reloaded  anaty direct chat screen');
    state?._reloadFromSocket();
  }
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  late final DirectChatController controller;
  DateTime? _previousDate;

  @override
  void initState() {
    super.initState();
    controller = DirectChatController(widget.contactId)..init();
    controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    print('Socket reloaded tonga à destination direct chat screen');
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await controller.reload();
  }

  Future<void> _reloadFromSocket() async {
    print('Socket reloaded anaty controller direct chat screen');
    await controller.reloadFromSocket();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DirectChatAppBar(contactId: widget.contactId),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (controller.previewFile != null)
            FilePreview(
              file: controller.previewFile!,
              type: controller.previewType!,
              onCancel: controller.clearPreview,
              onSend: () => controller.sendFile(context),
            ),
          if (controller.isRecording)
            RecordingInterface(
              onStop: controller.stopRecording,
              onCancel: controller.cancelRecording,
              showDuration: true,
            ),
          DirectInputArea(controller: controller),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun message',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: controller.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: controller.messages.length,
      itemBuilder: (context, i) {
        final wrapper = controller.messages[i];
        final msg = wrapper.message;
        final showDate = _shouldShowDate(msg.dateEnvoi);
        _previousDate = msg.dateEnvoi;

        // ✅ Trouve le contact (celui qui N'EST PAS l'expéditeur du message)
        final contact = _getContact(msg);

        return Column(
          children: [
            if (showDate) MessageDateBadge(date: msg.dateEnvoi),
            DirectMessageWidget(
              message: msg,
              contact: contact,
              isSending: wrapper.isSending,
              sendFailed: wrapper.sendFailed,
              onCopy: () => _copy(msg),
              onDelete: (id) => controller.deleteMessage(id),
              onTransfer: _transfer,
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowDate(DateTime date) {
    if (_previousDate == null) return true;
    return DateTime(date.year, date.month, date.day) !=
        DateTime(_previousDate!.year, _previousDate!.month, _previousDate!.day);
  }

  // ✅ Retourne le contact (celui avec contactId)
  User _getContact(DirectMessage msg) {
    return msg.expediteur.id == widget.contactId
        ? msg.expediteur
        : msg.destinataire;
  }

  Future<void> _copy(DirectMessage msg) async {
    await Clipboard.setData(ClipboardData(text: msg.contenu.texte ?? ''));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copié'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _transfer(String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContaScreen(isTransferMode: true, id: id),
      ),
    );
    await controller.reload();
  }
}

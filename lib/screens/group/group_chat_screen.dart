// lib/screens/group/group_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mini_social_network/models/group_message.dart';
import 'package:mini_social_network/widgets/messages/group_message_widget.dart';
import 'package:mini_social_network/widgets/voice_recording_widget.dart';
import 'package:mini_social_network/screens/ctt_screen.dart';
import 'package:mini_social_network/screens/group/services/group_chat_controller.dart';
import 'package:mini_social_network/screens/group/widgets/group_chat_app_bar.dart';
import 'package:mini_social_network/screens/group/widgets/group_input_area.dart';
import 'package:mini_social_network/screens/direct/widgets/file_preview.dart';
import 'package:mini_social_network/screens/direct/widgets/message_date_badge.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  static final GlobalKey<_GroupChatScreenState> groupChatScreenKey =
      GlobalKey<_GroupChatScreenState>();

  GroupChatScreen({required this.groupId}) : super(key: groupChatScreenKey);

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();

  void reload() {
    final state = groupChatScreenKey.currentState;
    print('🔵 [GroupChatScreen] reload() appelé depuis l\'extérieur');
    state?._reload();
  }

  void reloadFromSocket() {
    final state = groupChatScreenKey.currentState;
    print(
        '🔌 [GroupChatScreen] reloadFromSocket() appelé depuis SocketService');
    state?._reloadFromSocket();
  }
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  late final GroupChatController controller;
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    print('🟢 [GroupChatScreen] initState() - groupId: ${widget.groupId}');

    CurrentScreenManager.currentScreen = 'groupChat';
    print(
        '📍 [GroupChatScreen] Current screen mis à jour: ${CurrentScreenManager.currentScreen}');

    controller = GroupChatController(widget.groupId)..init();
    controller.addListener(_onControllerUpdate);
    print('✅ [GroupChatScreen] Listener ajouté au controller');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyState = GroupChatScreen.groupChatScreenKey.currentState;
      if (keyState != null) {
        print('✅ [GroupChatScreen] GlobalKey.currentState est accessible');
      } else {
        print('❌ [GroupChatScreen] GlobalKey.currentState est NULL !');
      }
    });
  }

  void _onControllerUpdate() {
    _updateCount++;
    print('🔔 [GroupChatScreen] _onControllerUpdate() appelé (#$_updateCount)');
    print('   📊 Nombre de messages: ${controller.messages.length}');

    if (mounted) {
      print('   ✅ Widget mounted - setState() appelé');
      setState(() {});
    } else {
      print('   ⚠️ Widget NOT mounted - setState() ignoré');
    }
  }

  @override
  void dispose() {
    print('🔴 [GroupChatScreen] dispose() - removing listener');
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    print('🔄 [GroupChatScreen] _reload() appelé');
    await controller.reload();
    print('✅ [GroupChatScreen] _reload() terminé');
  }

  Future<void> _reloadFromSocket() async {
    print('🔌 [GroupChatScreen] _reloadFromSocket() appelé');
    await controller.reloadFromSocket();
    print('✅ [GroupChatScreen] _reloadFromSocket() terminé');
  }

  @override
  Widget build(BuildContext context) {
    print(
        '🎨 [GroupChatScreen] build() appelé - messages: ${controller.messages.length}');

    return Scaffold(
      appBar: GroupChatAppBar(
        controller: controller,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (controller.previewFile != null)
            FilePreview(
              file: controller.previewFile!,
              type: controller.previewType!,
              onCancel: controller.previewType == 'audio'
                  ? controller.clearAudioPreview
                  : controller.clearPreview,
            ),
          if (controller.isRecording)
            RecordingInterface(
              onStop: controller.stopRecording,
              onCancel: controller.cancelRecording,
              showDuration: true,
            ),
          GroupInputArea(controller: controller),
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

    print(
        '📝 [GroupChatScreen] Rendering ${controller.messages.length} messages');

    // ✅ Inverse l'ordre des messages pour le reverse ListView
    final reversedMessages = controller.messages.reversed.toList();

    return ListView.builder(
      controller: controller.scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: reversedMessages.length,
      itemBuilder: (context, i) {
        final wrapper = reversedMessages[i];
        final msg = wrapper.message;

        // ✅ Compare avec le message SUIVANT dans la liste inversée
        final bool showDate;
        if (i == reversedMessages.length - 1) {
          showDate = true;
        } else {
          final nextMsg = reversedMessages[i + 1].message;
          showDate = _isDifferentDay(msg.dateEnvoi, nextMsg.dateEnvoi);
        }

        return Column(
          children: [
            if (showDate) MessageDateBadge(date: msg.dateEnvoi),
            GroupMessageWidget(
              message: msg,
              currentUser: controller.currentUser?.id ?? '',
              isSending: wrapper.isSending,
              sendFailed: wrapper.sendFailed,
              onDelete: (id) => controller.deleteMessage(id),
              onTransfer: _transfer,
              onCopy: () => _copy(msg),
            ),
          ],
        );
      },
    );
  }

  bool _isDifferentDay(DateTime date1, DateTime date2) {
    return DateTime(date1.year, date1.month, date1.day) !=
        DateTime(date2.year, date2.month, date2.day);
  }

  Future<void> _copy(GroupMessage msg) async {
    final text = msg.contenu.texte;
    if (text != null) {
      await Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message copié'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun texte à copier')),
      );
    }
  }

  Future<void> _transfer(String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContaScreen(isTransferMode: true, messageId: id),
      ),
    );
    await controller.reloadSilently();
  }
}

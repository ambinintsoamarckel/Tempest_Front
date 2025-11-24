import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/direct/direct_chat_screen.dart';
import '../screens/group/group_chat_screen.dart';

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;

  NotificationService._internal();

  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  Future<void> init(BuildContext context) async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('avant click');
        if (response.payload != null) {
          _handleNotificationClick(response.payload!);
        }
      },
    );
  }

  Future<void> showNotification(int id, String title, String body, String payload) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  void _handleNotificationClick(String payload) {
    final data = payload.split('|');
    final type = data[0];
    final id = data[1];
    print('click notification');
    if (type == 'direct') {
      print('Direct');
      _navigatorKey?.currentState?.push(
        MaterialPageRoute(
          builder: (context) => DirectChatScreen(contactId: id),
        ),
      );
    } else if (type == 'group') {
      print('Group');
      _navigatorKey?.currentState?.push(
        MaterialPageRoute(
          builder: (context) => GroupChatScreen(groupId: id),
        ),
      );
    }
  }
}

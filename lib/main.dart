import 'package:flutter/material.dart';
import 'screens/direct_chat_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Réseau Social',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DirectChatScreen(),
    );
  }
}

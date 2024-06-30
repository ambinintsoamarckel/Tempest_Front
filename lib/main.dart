import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/direct_chat_screen.dart';
import 'models/user.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Houatsappy',
      debugShowCheckedModeBanner: false, // Désactive le ruban "Debug"
      theme: ThemeData(
        primarySwatch: Colors.teal, // Couleur principale
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.orange, // Couleur d'accentuation
        ),
        scaffoldBackgroundColor: Colors.grey[200], // Couleur de fond
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal, // Couleur de l'AppBar
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.teal, // Couleur du bouton flottant
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(user: ModalRoute.of(context)!.settings.arguments as UserModel),
        '/direct_chat': (context) => DirectChatScreen(),
      },
    );
  }
}

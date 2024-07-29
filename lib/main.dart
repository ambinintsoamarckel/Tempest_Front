import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'models/user.dart';
import 'services/user_service.dart';
import 'screens/register_screen.dart';
import 'socket/socket_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import './socket/notification_service.dart';
import 'dart:io';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  bool isOnline = await checkConnectivity();
  runApp(isOnline ? const MyApp() : const NoConnectionApp());
}

Future<bool> checkConnectivity() async {
  try {
    final result = await InternetAddress.lookup('mahm.tempest.dov');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  }
}

class NoConnectionApp extends StatelessWidget {
  const NoConnectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pas de connexion',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Pas de connexion'),
        ),
        body: const Center(
          child: Text(
            'Impossible de se connecter à mahm.tempest.com. Vérifiez votre connexion Internet.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    notificationService.setNavigatorKey(navigatorKey);
    notificationService.init(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      title: 'Houatsappy',
      debugShowCheckedModeBanner: false, // Désactive le ruban "Debug"
      theme: ThemeData(
        primarySwatch: Colors.teal, // Couleur principale
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.orange, // Couleur d'accentuation
        ),
        scaffoldBackgroundColor: Colors.grey[200], // Couleur de fond
        appBarTheme: const AppBarTheme(
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
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.teal, // Couleur du bouton flottant
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as UserModel;
          return ProfileScreen();
        },
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();
  final socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  void _checkSession() async {
    try {
      UserModel isValidSession = await _userService.checkSession();
      socketService.initializeSocket(isValidSession.uid);
      Navigator.pushReplacementNamed(context, '/home', arguments: isValidSession);
    } catch (e) {
      Navigator.pushReplacementNamed(context, '/login');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

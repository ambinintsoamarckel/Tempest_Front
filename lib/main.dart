import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'models/user.dart';
import 'services/user_service.dart';
import 'screens/register_screen.dart';
import 'socket/socket_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import './socket/notification_service.dart';
import 'utils/connectivity.dart'; // Importation du fichier centralisé

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // Démarrage non bloquant : lance toujours l'application principale
  runApp(const MyApp());
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
            'Impossible de se connecter. Vérifiez votre connexion Internet.',
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.orange,
        ),
        scaffoldBackgroundColor: Colors.grey[200],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
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
          backgroundColor: Colors.teal,
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
      // Affiche l'écran NoConnectionApp si la route n'est pas trouvée
      onUnknownRoute: (settings) => MaterialPageRoute(builder: (context) => const NoConnectionApp()),
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
    _initializeApp();
  }

  void _initializeApp() async {
    // Vérifie la connectivité avant tout
    bool isConnected = await checkConnectivity();
    if (!isConnected) {
      // Redirige vers un écran d'erreur ou affiche un dialogue
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NoConnectionApp()));
      return;
    }

    // Si connecté, vérifie la session
    try {
      UserModel isValidSession = await _userService.checkSession();
      socketService.initializeSocket(isValidSession.uid);
      Navigator.pushReplacementNamed(context, '/home', arguments: isValidSession);
    } catch (e) {
      // Si la session n'est pas valide, redirige vers la page de connexion
      Navigator.pushReplacementNamed(context, '/login');
      // Pas de rethrow pour éviter les erreurs inutiles dans la console
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'models/user.dart';
import 'services/user_service.dart';
import 'screens/register_screen.dart';
import 'socket/socket_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import './socket/notification_service.dart';
import 'utils/connectivity.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // Envelopper l'app avec ChangeNotifierProvider
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class NoConnectionApp extends StatelessWidget {
  const NoConnectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Utiliser Consumer pour accéder au thème
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Pas de connexion',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Pas de connexion'),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 80,
                    color: AppTheme.accentColor.withOpacity(0.6),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pas de connexion Internet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Vérifiez votre connexion et réessayez',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Redémarrer l'app ou réessayer la connexion
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        print('🏗️ MyApp rebuild - ThemeMode: ${themeProvider.themeMode}');
        print('🏗️ isDarkMode: ${themeProvider.isDarkMode}');

        return MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [routeObserver],
          title: 'Houatsappy',
          debugShowCheckedModeBanner: false,

          // Utilisation du nouveau système de thème
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode, // Utilise le thème du provider

          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/profile': (context) {
              final user =
                  ModalRoute.of(context)!.settings.arguments as UserModel;
              return const ProfileScreen();
            },
            '/register': (context) => const RegisterScreen(),
          },
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (context) => const NoConnectionApp(),
          ),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final socketService = SocketService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeApp() async {
    // Attendre un peu pour l'animation
    await Future.delayed(const Duration(milliseconds: 800));

    // Vérifie la connectivité avant tout
    bool isConnected = await checkConnectivity();
    if (!isConnected && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NoConnectionApp()),
      );
      return;
    }

    // Si connecté, vérifie la session
    try {
      UserModel isValidSession = await _userService.checkSession();
      socketService.initializeSocket(isValidSession.uid);
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: isValidSession,
        );
      }
    } catch (e) {
      // Si la session n'est pas valide, redirige vers la page de connexion
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo de l'application avec gradient
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/icon.png',
                        height: 180,
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Nom de l'application
                    const Text(
                      'Houatsappy',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Connectez-vous avec vos proches',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Indicateur de chargement moderne
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

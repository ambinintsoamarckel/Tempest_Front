import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'models/user.dart';
import 'services/user_service.dart';
import 'services/current_screen_manager.dart';
import 'screens/register_screen.dart';
import 'package:intl/date_symbol_data_local.dart';


final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
    await initializeDateFormatting('fr_FR', null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
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
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as UserModel;
          return ProfileScreen(user: user);
        },
        '/register': (context) => RegisterScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  void _checkSession() async {
    try {
       UserModel isValidSession = await _userService.checkSession();
    if (isValidSession!=null) {
      Navigator.pushReplacementNamed(context, '/home', arguments: isValidSession);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
      
    catch (e) {
      Navigator.pushReplacementNamed(context, '/login');
      throw(e);
      
    }
     }

   

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}


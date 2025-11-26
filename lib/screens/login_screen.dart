import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'package:mini_social_network/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  void _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        _showSnackBar('Veuillez remplir tous les champs.', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      UserModel? user =
          await _userService.signInWithEmailAndPassword(email, password);

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home', arguments: user);
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Gradient de fond
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.15),
                  AppTheme.secondaryColor.withOpacity(0.1),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo avec animation
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.secondaryColor.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
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
                        ),

                        const SizedBox(height: 40),

                        // Titre
                        Text(
                          'Content de vous revoir!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Veuillez vous connecter à votre compte',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Carte de formulaire
                        Card(
                          elevation: 8,
                          shadowColor: AppTheme.primaryColor.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                // Email
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'E-mail',
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 20),

                                // Mot de passe
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Mot de passe',
                                  icon: Icons.lock_rounded,
                                  isPassword: true,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: AppTheme.primaryColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Bouton de connexion
                                _buildLoginButton(),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Lien vers inscription
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Pas encore de compte? ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: _navigateToRegister,
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('Créer un compte'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Overlay de chargement
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Connexion en cours...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[50]
            : Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: AppTheme.primaryColor.withOpacity(0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Se connecter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

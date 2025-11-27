import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'contacts_screen.dart';
import 'messages_screen.dart';
import 'stories_screen.dart';
import 'profile/profile_screen.dart';
import '../models/user.dart';
import 'custom_search_delegate.dart';
import '../utils/connectivity.dart';
import '../theme/app_theme.dart';
import '../utils/screen_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 1; // Messages par défaut
  bool _isOnline = true;
  late UserModel user;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  DateTime? _lastPressedAt;

  // ✅ PageController pour gérer le swipe
  late PageController _pageController;

  // GlobalKeys pour les enfants
  late GlobalKey<StoryScreenState> storyScreenKey;
  late GlobalKey<ConversationListScreenState> conversationListScreen;
  late GlobalKey<ContactScreenState> contactScreenState;

  final List<NavItem> _navItems = [
    NavItem(
        icon: Icons.contacts_rounded,
        label: 'Contacts',
        index: 0,
        route: '/home/contacts'),
    NavItem(
        icon: Icons.chat_bubble_rounded,
        label: 'Messages',
        index: 1,
        route: '/home/messages'),
    NavItem(
        icon: Icons.auto_awesome_rounded,
        label: 'Stories',
        index: 2,
        route: '/home/stories'),
  ];

  @override
  void initState() {
    super.initState();

    // Créer les GlobalKey pour les enfants
    storyScreenKey = GlobalKey<StoryScreenState>();
    conversationListScreen = GlobalKey<ConversationListScreenState>();
    contactScreenState = GlobalKey<ContactScreenState>();

    // ✅ Initialiser le PageController avec la page par défaut (Messages = index 1)
    _pageController = PageController(initialPage: _selectedIndex);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _performConnectivityCheck();
  }

  Future<void> _performConnectivityCheck() async {
    bool isConnected = await checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = isConnected;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Déterminer l'index basé sur la route actuelle
    final route = ModalRoute.of(context)?.settings.name;
    if (route != null) {
      int newIndex = _selectedIndex;
      if (route.contains('contacts')) {
        newIndex = 0;
      } else if (route.contains('messages')) {
        newIndex = 1;
      } else if (route.contains('stories')) {
        newIndex = 2;
      }

      // ✅ Mettre à jour le PageController après que le widget soit construit
      if (newIndex != _selectedIndex) {
        _selectedIndex = newIndex;
        // Utiliser addPostFrameCallback pour s'assurer que le PageView est construit
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(newIndex);
          }
        });
      }
    }

    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null && args is UserModel) {
      user = args;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose(); // ✅ Dispose du PageController
    super.dispose();
  }

  // ✅ Méthode mise à jour pour gérer la navigation
  void _onNavItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      // ✅ Animer le changement de page
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Naviguer vers la nouvelle route
      final currentRoute = _navItems[index].route;
      Navigator.of(context).pushReplacementNamed(
        currentRoute,
        arguments: user,
      );
    }
  }

  // ✅ Nouvelle méthode appelée quand on swipe
  void _onPageChanged(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      _animationController.reset();
      _animationController.forward();

      // Naviguer vers la nouvelle route
      final currentRoute = _navItems[index].route;
      Navigator.of(context).pushReplacementNamed(
        currentRoute,
        arguments: user,
      );
    }
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final maxDuration = const Duration(seconds: 2);
    final isWarning =
        _lastPressedAt == null || now.difference(_lastPressedAt!) > maxDuration;

    if (isWarning) {
      _lastPressedAt = now;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Appuyez encore une fois pour quitter',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _isOnline ? _buildOnlineContent(isDark) : _buildOfflineContent(),
      ),
    );
  }

  Widget _buildOnlineContent(bool isDark) {
    return Column(
      children: [
        // Header avec navigation
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).appBarTheme.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // AppBar personnalisée
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Logo et titre
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.secondaryColor
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/icon.png',
                          height: 22,
                          width: 22,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Houatsappy',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      // Actions
                      if (_selectedIndex == 1)
                        IconButton(
                          icon: const Icon(Icons.search_rounded),
                          onPressed: () {
                            showSearch(
                              context: context,
                              delegate: CustomSearchDelegate(),
                            );
                          },
                          tooltip: 'Rechercher',
                        ),
                      IconButton(
                        icon: const Icon(Icons.account_circle_rounded),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileScreen()),
                          );
                        },
                        tooltip: 'Profil',
                      ),
                    ],
                  ),
                ),

                // Navigation horizontale
                Container(
                  height: 60,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: _navItems.map((item) {
                      final isSelected = _selectedIndex == item.index;
                      return Expanded(
                        child: _buildNavButton(item, isSelected, isDark),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ✅ Contenu avec PageView pour le swipe
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              ContactScreen(contactScreenKey: contactScreenState),
              ConversationListScreen(
                  conversationListScreenKey: conversationListScreen),
              StoryScreen(storyScreenKey: storyScreenKey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton(NavItem item, bool isSelected, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNavItemTapped(item.index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : isDark
                      ? Colors.grey[800]
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected
                        ? Colors.white
                        : isDark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                    size: 22,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
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
          Text(
            'Vérifiez votre connexion et réessayez',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final int index;
  final String route;

  NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.route,
  });
}

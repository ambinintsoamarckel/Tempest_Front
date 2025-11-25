import 'dart:io';
import 'package:flutter/material.dart';
import 'contacts_screen.dart';
import 'messages_screen.dart';
import 'stories_screen.dart';
import 'profile/profile_screen.dart';
import '../models/user.dart';
import 'custom_search_delegate.dart';
import '../utils/connectivity.dart'; // Importation du fichier centralisé

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOnline = true;
  late UserModel user;
  static  GlobalKey<StoryScreenState> storyScreenKey = GlobalKey<StoryScreenState>();
  static  GlobalKey<ConversationListScreenState> conversationListScreen = GlobalKey<ConversationListScreenState>();
  static  GlobalKey<ContactScreenState> contactScreenState = GlobalKey<ContactScreenState>();
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
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
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null && args is UserModel) {
      user = args;
    } else {
      // Handle the case where arguments are missing or not the expected type
      Navigator.of(context).pop(); // Go back if no valid user is provided
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isOnline ? const Text('HOUATSAPPY') : const Text('Offline'),
        actions: _isOnline
            ? [
                if (_tabController.index == 1)
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      showSearch(
                        context: context,
                        delegate: CustomSearchDelegate(),
                      );
                    },
                  ),
                if (_tabController.index == 2)
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CameraScreen()),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
              ]
            : null,
        bottom: _isOnline
            ? PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
                        Tab(icon: Icon(Icons.message), text: 'Messages'),
                        Tab(icon: Icon(Icons.photo), text: 'Stories'),
                      ],
                    ),
                    const Divider(
                      height: 1,
                      color: Colors.grey,
                    ),
                  ],
                ),
              )
            : null,
      ),
      body: _isOnline
          ? TabBarView(
              controller: _tabController,
              children: [
                ContactScreen(contactScreenKey: contactScreenState),
                ConversationListScreen(conversationListScreenKey:  conversationListScreen), // Utilisez la clé ici
                StoryScreen(storyScreenKey: storyScreenKey),
              ],
            )
          : const Center(child: Text('No internet connection')),
      floatingActionButton: _isOnline ? _buildFloatingActionButton() : null,
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 0: // Contacts tab
        return FloatingActionButton(
          onPressed: () {
            // Action pour ajouter un nouveau contact
          },
          child: const Icon(Icons.person_add),
        );
      case 1: // Messages tab
        return FloatingActionButton(
          onPressed: () {
            // Action pour ajouter un nouveau message
          },
          child: const Icon(Icons.message),
        );
      case 2: // Stories tab
        return FloatingActionButton(
          onPressed: () {
            // Action pour ajouter une nouvelle story
          },
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }
}

// Classe d'exemple pour la caméra
class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caméra'),
      ),
      body: const Center(
        child: Text('Intégration de la caméra ici'),
      ),
    );
  }
}

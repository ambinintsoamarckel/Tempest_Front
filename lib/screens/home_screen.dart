import 'dart:io';
import 'package:flutter/material.dart';
import 'contacts_screen.dart';
import 'messages_screen.dart';
import 'stories_screen.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _isOnline = true;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        _isOnline = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: _isOnline
              ? const Text('HOUATSAPPY')
              : const Text('Offline'),
          actions: _isOnline
              ? [
                  if (_tabController.index == 1)
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        showSearch(context: context, delegate: CustomSearchDelegate());
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
                        MaterialPageRoute(builder: (context) => const AccountScreen()),
                      );
                    },
                  ),
                ]
              : null,
          bottom: _isOnline
              ? TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
                    Tab(icon: Icon(Icons.message), text: 'Messages'),
                    Tab(icon: Icon(Icons.photo), text: 'Stories'),
                  ],
                )
              : null,
        ),
        body: _isOnline
            ? TabBarView(
                controller: _tabController,
                children: const [
                  ContactScreen(),
                  ConversationListScreen(),
                  StoryScreen(),
                ],
              )
            : const Center(child: Text('No internet connection')),
        floatingActionButton: _isOnline ? _buildFloatingActionButton() : null,
      ),
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

// Classe de recherche personnalisée
class CustomSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text('Résultats de la recherche pour "$query"'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(
      child: Text('Suggestions de recherche pour "$query"'),
    );
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


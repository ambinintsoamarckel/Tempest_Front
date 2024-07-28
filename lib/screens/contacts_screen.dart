import 'package:flutter/material.dart';
import 'package:mini_social_network/screens/group_chat_screen.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import '../models/contact.dart';
import '../widgets/contact_widget.dart';
import '../services/contact_service.dart';
import '../screens/direct_chat_screen.dart';

class ContactScreen extends StatefulWidget {
  final GlobalKey<ContactScreenState> contactScreenKey;
  const ContactScreen({required this.contactScreenKey}) : super(key: contactScreenKey);
  
  @override
  ContactScreenState createState() => ContactScreenState();

  void reload() {
    final state = contactScreenKey.currentState;
    if (state != null) {
      state._reload();
    }
  }
}
class ContactScreenState extends State<ContactScreen> {
  final ContactService _contactService = ContactService();
  final List<Contact> _contacts = [];
  final List<Contact> _filteredContacts = [];
  final Set<Contact> _selectedContacts = {};
  final TextEditingController _searchController = TextEditingController();
  final CurrentScreenManager screenManager = CurrentScreenManager();
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    screenManager.updateCurrentScreen('contact');
  }

  Future<void> _loadContacts() async {
    try {
      List<Contact> contacts = await _contactService.getContacts();
      setState(() {
        _contacts.addAll(contacts);
        _filteredContacts.addAll(contacts);
      });
    } catch (e) {
      print('Failed to load contacts: $e');
    }
  }

  Future<void> _reload() async {
    try {
      List<Contact> contacts = await _contactService.getContacts();
      setState(() {
        _contacts.clear();
        _filteredContacts.clear();
        _contacts.addAll(contacts);
        _filteredContacts.addAll(contacts);
      });
    } catch (e) {
      print('Failed to load contacts: $e');
    }
  }

  void _selectContact(Contact contact) {
    if (_selectedContacts.isNotEmpty) {
      _toggleSelection(contact);
    } else {
      _navigateToChat(contact);
    }
  }

  void _navigateToChat(Contact contact) {
    if (contact.type == 'groupe') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupChatScreen(groupId: contact.id),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DirectChatScreen(id: contact.id),
        ),
      );
    }
  }

  void _viewStory(Contact contact) {
    // Logique pour naviguer vers la story de l'utilisateur
    // Navigator.push(context, MaterialPageRoute(builder: (context) => StoryScreen(id: contact.id)));
    print('Navigating to story of ${contact.nom}');
  }

  void _filterContacts(String query) {
    List<Contact> filteredContacts = _contacts.where((contact) {
      return contact.nom.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredContacts.clear();
      _filteredContacts.addAll(filteredContacts);
    });
  }

  void _toggleSelection(Contact contact) {
    setState(() {
      if (_selectedContacts.contains(contact)) {
        _selectedContacts.remove(contact);
        if (_selectedContacts.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedContacts.add(contact);
        _isSelectionMode = true;
      }
    });
  }

  void _showCreateGroupDialog() {
    final TextEditingController groupNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Créer un groupe'),
          content: TextField(
            controller: groupNameController,
            decoration: const InputDecoration(hintText: 'Nom du groupe'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                _createGroup(groupNameController.text);
                Navigator.pop(context);
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createGroup(String groupName) async {
    if (_selectedContacts.length < 2) {
      return; // Ne pas créer un groupe si moins de deux utilisateurs sont sélectionnés
    }

    List<String> userIds = _selectedContacts.map((contact) => contact.id).toList();
    try {
      String? groupId = await _contactService.createGroup(userIds, groupName);
      // Afficher un message de succès ou naviguer vers l'écran du groupe nouvellement créé
      // Réinitialiser la sélection
      setState(() {
        _selectedContacts.clear();
        _isSelectionMode = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupChatScreen(groupId: groupId!),
        ),
      );
    } catch (e) {
      print('Failed to create group: $e');
      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec de la création du groupe')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedContacts.length} sélectionné(s)')
            : const Text('Contacts'),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.group_add),
                  onPressed: _showCreateGroupDialog,
                ),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80.0), // Hauteur augmentée
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterContacts,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: _filteredContacts.isNotEmpty
          ? ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                final isSelected = _selectedContacts.contains(contact);
                return GestureDetector(
                  onTap: () => _selectContact(contact),
                  onLongPress: () => _toggleSelection(contact),
                  child: Card(
                    color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ContactWidget(contact: contact),
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

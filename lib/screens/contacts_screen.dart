import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../widgets/contact_widget.dart';
import '../services/contact_service.dart';
/* import '../screens/chat_screen.dart'; // Importer l'écran de discussion
import '../screens/create_group_screen.dart'; // Importer l'écran de création de groupe
import '../screens/view_story_screen.dart'; / */

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final ContactService _contactService = ContactService();
  late List<Contact> _contacts;
  late List<Contact> _filteredContacts;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _filteredContacts = [];
  }

  Future<void> _loadContacts() async {
    try {
      List<Contact> contacts = await _contactService.getContacts();
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts; // Initialize filtered contacts with all contacts
      });
    } catch (e) {
      print('Failed to load contacts: $e');
      // Handle error gracefully
    }
  }

  void _navigateToChat(Contact contact) {
    // Navigate to chat screen with the contact
    /* Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(contact: contact),
      ),
    ); */
  }

  void _showOptions(Contact contact) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.group),
              title: Text('Créer un groupe avec ${contact.name}'),
              onTap: () {
                Navigator.pop(context);
                _createGroupWithContact(contact);
              },
            ),
            /* if (contact.hasActiveStory)
              ListTile(
                leading: const Icon(Icons.image),
                title: Text('Voir la story de ${contact.name}'),
                onTap: () {
                  Navigator.pop(context);
                  _viewStory(contact);
                },
              ), */
          ],
        );
      },
    );
  }

  void _createGroupWithContact(Contact contact) {
    // Navigate to create group screen with the contact
    /* Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupScreen(contact: contact),
      ),
    ); */
  }

  void _viewStory(Contact contact) {
    // Navigate to view story screen with the contact
    /* Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewStoryScreen(contact: contact),
      ),
    ); */
  }

  void _filterContacts(String query) {
    List<Contact> filteredContacts = _contacts.where((contact) {
      return contact.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredContacts = filteredContacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: TextField(
                controller: _searchController,
                onChanged: _filterContacts,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _filteredContacts != null
          ? ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _navigateToChat(_filteredContacts[index]),
                  onLongPress: () => _showOptions(_filteredContacts[index]),
                  child: ContactWidget(contact: _filteredContacts[index]),
                );
              },
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import '../models/contact.dart';
import '../widgets/contact_widget.dart';
import '../services/contact_service.dart';

class ContactScreen extends StatefulWidget {
  static final GlobalKey<_ContactScreenState> contactScreenKey= GlobalKey<_ContactScreenState>();
  ContactScreen() : super(key: contactScreenKey);
  @override
  _ContactScreenState createState() => _ContactScreenState();

 void reload()
 {
     final state = contactScreenKey.currentState;
    if (state != null) {
      state._reload();
    }
 }
}

class _ContactScreenState extends State<ContactScreen> {
  final ContactService _contactService = ContactService();
  final List<Contact> _contacts = [];
  final List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  final CurrentScreenManager screenManager=CurrentScreenManager();

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
    Navigator.pop(context, contact);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterContacts,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
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
          return GestureDetector(
            onTap: () => _selectContact(_filteredContacts[index]),
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: ContactWidget(contact: _filteredContacts[index]),
              ),
            ),
          );
        },
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

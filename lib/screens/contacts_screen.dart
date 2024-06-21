import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../widgets/contact_widget.dart';
import '../services/contact_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final ContactService _contactService = ContactService(baseUrl: 'http://your_api_base_url_here');
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      // Replace with actual contact loading logic
      List<Contact> contacts = await _contactService.getContacts();
      setState(() {
        _contacts.addAll(contacts);
        _filteredContacts = contacts;
      });
    } catch (e) {
      print('Failed to load contacts: $e');
    }
  }

  void _filterContacts(String query) {
    List<Contact> filtered = _contacts.where((contact) {
      return contact.name.toLowerCase().contains(query.toLowerCase()) ||
          contact.id.contains(query);
    }).toList();

    setState(() {
      _filteredContacts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher',
                border: OutlineInputBorder(),
              ),
              onChanged: _filterContacts,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _filteredContacts.length,
        itemBuilder: (context, index) {
          return ContactWidget(contact: _filteredContacts[index]);
        },
      ),
    );
  }
}

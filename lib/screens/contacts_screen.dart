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
  final List<Contact> _filteredContacts = [];
  final ContactService _contactService = ContactService(baseUrl: 'http://your_api_base_url_here');
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _contactService.fetchContacts();
      setState(() {
        _contacts.addAll(contacts);
        _filteredContacts.addAll(contacts);
      });
    } catch (e) {
      print('Failed to load contacts: $e');
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts.clear();
      _filteredContacts.addAll(_contacts.where((contact) {
        return contact.name.toLowerCase().contains(query) ||
            contact.phoneNumber.contains(query);
      }).toList());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
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

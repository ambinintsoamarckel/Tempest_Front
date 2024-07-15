import 'package:flutter/material.dart';
import 'package:mini_social_network/services/discu_message_service.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';
import '../services/current_screen_manager.dart';
import '../widgets/contact_widget.dart';

class ContaScreen extends StatefulWidget {
  final bool isTransferMode;
  final String id;

  const ContaScreen({Key? key, this.isTransferMode = false, required this.id}) : super(key: key);

  @override
  _ContaScreenState createState() => _ContaScreenState();
}

class _ContaScreenState extends State<ContaScreen> {
  final ContactService _contactService = ContactService();
  final List<Contact> _contacts = [];
  final List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  final CurrentScreenManager screenManager = CurrentScreenManager();
  final MessageService _messageService = MessageService();
  bool _isSending = false;
  Contact? _selectedContact;
  List<Contact> _sentContacts = [];

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

  void _filterContacts(String query) {
    List<Contact> filteredContacts = _contacts.where((contact) {
      return contact.nom.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredContacts.clear();
      _filteredContacts.addAll(filteredContacts);
    });
  }

  void _selectContact(Contact contact) async {
    setState(() {
      _isSending = true;
      _selectedContact = contact;
    });

    try {
      await _messageService.transferMessage(contact.id, widget.id);
      setState(() {
        _sentContacts.add(contact);
        _isSending = false;
        _selectedContact = null;
      });
    } catch (e) {
      print('Failed to send message: $e');
      setState(() {
        _isSending = false;
        _selectedContact = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                Contact contact = _filteredContacts[index];
                bool isSent = _sentContacts.contains(contact);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ContactWidget(contact: contact),
                        ),
                        if (widget.isTransferMode)
                          isSent
                              ? const Text('Envoyé', style: TextStyle(color: Colors.green))
                              : _selectedContact == contact && _isSending
                                  ? const CircularProgressIndicator()
                                  : TextButton(
                                      onPressed: _isSending
                                          ? null
                                          : () => _selectContact(contact),
                                      child: const Text('Envoyer'),
                                    ),
                      ],
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

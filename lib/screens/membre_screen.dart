import 'package:flutter/material.dart';
import 'package:mini_social_network/models/group_message.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';
import '../services/discu_group_service.dart';
import '../services/current_screen_manager.dart';
import '../widgets/contact_widget.dart';

class ContaScreen extends StatefulWidget {
  final String groupId;

  const ContaScreen({super.key, required this.groupId});

  @override
  _ContaScreenState createState() => _ContaScreenState();
}

class _ContaScreenState extends State<ContaScreen> {
  final ContactService _contactService = ContactService();
  final GroupChatService _groupService = GroupChatService();
  final List<Contact> _contacts = [];
  final List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  final CurrentScreenManager screenManager = CurrentScreenManager();
  bool _isAdding = false;
  Contact? _selectedContact;
  final List<Contact> _addedContacts = [];
  List<Group> groupes=[];

  @override
  void initState() {
    super.initState();
    _loadContacts();
    screenManager.updateCurrentScreen('contact');
  }

  Future<void> _loadContacts() async {
    try {
      List<Contact> contacts = await _contactService.getNonMembre(widget.groupId);
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

  void _addMember(Contact contact) async {
    setState(() {
      _isAdding = true;
      _selectedContact = contact;
    });

    try {
      final groupe = await _groupService.addMemberToGroup(widget.groupId, contact.id);
      setState(() {
        _addedContacts.add(contact);
        groupes.add(groupe); // Add the contact to _addedContacts
        _isAdding = false;
        _selectedContact = null;
      });
    } catch (e) {
      print('Failed to add member to group: $e');
      setState(() {
        _isAdding = false;
        _selectedContact = null;
      });
    }
  }

  void _goBack() {
    Navigator.pop(context, groupes.isNotEmpty ? groupes.last : null);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajouter des membres'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
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
                  bool isAdded = _addedContacts.contains(contact);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ContactWidget(contact: contact),
                          ),
                          isAdded
                              ? const Text('Ajouté', style: TextStyle(color: Colors.green))
                              : _selectedContact == contact && _isAdding
                                  ? const CircularProgressIndicator()
                                  : TextButton(
                                      onPressed: _isAdding ? null : () => _addMember(contact),
                                      child: const Text('Ajouter'),
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
      ),
    );
  }
}

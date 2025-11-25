import 'package:flutter/material.dart';
import 'package:mini_social_network/screens/group/group_chat_screen.dart';
import 'package:mini_social_network/services/current_screen_manager.dart';
import '../models/contact.dart';
import '../widgets/contact_widget.dart';
import '../services/contact_service.dart';
import '../theme/app_theme.dart';
import 'direct/direct_chat_screen.dart';

class ContactScreen extends StatefulWidget {
  final GlobalKey<ContactScreenState> contactScreenKey;
  const ContactScreen({required this.contactScreenKey})
      : super(key: contactScreenKey);

  @override
  ContactScreenState createState() => ContactScreenState();

  void reload() {
    final state = contactScreenKey.currentState;
    if (state != null) {
      state._silentReload();
    }
  }
}

class ContactScreenState extends State<ContactScreen>
    with SingleTickerProviderStateMixin {
  final ContactService _contactService = ContactService();
  final List<Contact> _contacts = [];
  final List<Contact> _filteredContacts = [];
  final Set<Contact> _selectedContacts = {};
  final TextEditingController _searchController = TextEditingController();
  final CurrentScreenManager screenManager = CurrentScreenManager();

  bool _isSelectionMode = false;
  bool _isInitialLoading = true;
  bool _isSilentLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _loadContacts();
    screenManager.updateCurrentScreen('contact');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      List<Contact> contacts = await _contactService.getContacts();
      if (mounted) {
        setState(() {
          _contacts
            ..clear()
            ..addAll(contacts);
          _filteredContacts
            ..clear()
            ..addAll(contacts);
          _isInitialLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      print('❌ Failed to load contacts: $e');
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  /// 🔇 Silent reload - pas de loader visible
  Future<void> _silentReload() async {
    if (_isSilentLoading) return;

    setState(() => _isSilentLoading = true);

    try {
      List<Contact> contacts = await _contactService.getContacts();
      if (mounted) {
        setState(() {
          _contacts
            ..clear()
            ..addAll(contacts);
          _filteredContacts
            ..clear()
            ..addAll(contacts);
          _isSilentLoading = false;
        });

        // Réappliquer le filtre de recherche si nécessaire
        if (_searchController.text.isNotEmpty) {
          _filterContacts(_searchController.text);
        }
      }
    } catch (e) {
      print('❌ Failed to silent reload contacts: $e');
      if (mounted) {
        setState(() => _isSilentLoading = false);
      }
    }
  }

  Future<void> _reload() async {
    await _silentReload();
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
          builder: (context) => DirectChatScreen(contactId: contact.id),
        ),
      );
    }
  }

  void _filterContacts(String query) {
    List<Contact> filteredContacts = _contacts.where((contact) {
      return contact.nom.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (mounted) {
      setState(() {
        _filteredContacts
          ..clear()
          ..addAll(filteredContacts);
      });
    }
  }

  void _toggleSelection(Contact contact) {
    if (mounted) {
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
  }

  void _cancelSelection() {
    if (mounted) {
      setState(() {
        _selectedContacts.clear();
        _isSelectionMode = false;
      });
    }
  }

  void _showCreateGroupDialog() {
    final TextEditingController groupNameController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group_add,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Créer un groupe'),
            ],
          ),
          content: TextField(
            controller: groupNameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nom du groupe',
              prefixIcon: const Icon(Icons.edit, color: AppTheme.primaryColor),
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (groupNameController.text.trim().isNotEmpty) {
                  _createGroup(groupNameController.text.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createGroup(String groupName) async {
    if (_selectedContacts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Sélectionnez au moins 2 contacts'),
              ),
            ],
          ),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    List<String> userIds =
        _selectedContacts.map((contact) => contact.id).toList();
    try {
      String? groupId = await _contactService.createGroup(userIds, groupName);

      if (mounted) {
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
      }
    } catch (e) {
      print('❌ Failed to create group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Échec de la création du groupe'),
                ),
              ],
            ),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isInitialLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement des contacts...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // AppBar moderne
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  title: _isSelectionMode
                      ? Text(
                          '${_selectedContacts.length} sélectionné${_selectedContacts.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Text(
                          'Contacts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  leading: _isSelectionMode
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _cancelSelection,
                        )
                      : null,
                  actions: _isSelectionMode
                      ? [
                          IconButton(
                            icon: const Icon(Icons.group_add),
                            tooltip: 'Créer un groupe',
                            onPressed: _showCreateGroupDialog,
                            color: AppTheme.primaryColor,
                          ),
                        ]
                      : null,
                ),

                // Barre de recherche
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterContacts,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un contact...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterContacts('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2C2C2C)
                            : Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                // Liste des contacts
                _filteredContacts.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchController.text.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.people_outline,
                                size: 64,
                                color: Theme.of(context)
                                    .iconTheme
                                    .color
                                    ?.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isNotEmpty
                                    ? 'Aucun contact trouvé'
                                    : 'Aucun contact',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final contact = _filteredContacts[index];
                              final isSelected =
                                  _selectedContacts.contains(contact);

                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: GestureDetector(
                                  onTap: () => _selectContact(contact),
                                  onLongPress: () => _toggleSelection(contact),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                              .withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: isSelected
                                          ? Border.all(
                                              color: AppTheme.primaryColor,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: ContactWidget(
                                        contact: contact,
                                        isSelected: isSelected,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _filteredContacts.length,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }
}

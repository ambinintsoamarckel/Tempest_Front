import 'package:flutter/material.dart';
import 'package:mini_social_network/services/discu_message_service.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';
import '../services/current_screen_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/contact_widget.dart';

class ContaScreen extends StatefulWidget {
  final bool isTransferMode;
  final String id;

  const ContaScreen({
    super.key,
    this.isTransferMode = false,
    required this.id,
  });

  @override
  _ContaScreenState createState() => _ContaScreenState();
}

class _ContaScreenState extends State<ContaScreen>
    with SingleTickerProviderStateMixin {
  final ContactService _contactService = ContactService();
  final List<Contact> _contacts = [];
  final List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  final CurrentScreenManager screenManager = CurrentScreenManager();
  final MessageService _messageService = MessageService();

  bool _isSending = false;
  bool _isInitialLoading = true;
  bool _isSilentLoading = false;
  Contact? _selectedContact;
  final List<Contact> _sentContacts = [];

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

  Future<void> _selectContact(Contact contact) async {
    setState(() {
      _isSending = true;
      _selectedContact = contact;
    });

    try {
      if (contact.type == 'groupe') {
        await _messageService.transferMessageGroupe(contact.id, widget.id);
      } else {
        await _messageService.transferMessage(contact.id, widget.id);
      }

      if (mounted) {
        setState(() {
          _sentContacts.add(contact);
          _isSending = false;
          _selectedContact = null;
        });

        // Afficher un feedback de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Message transféré à ${contact.nom}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Failed to send message: $e');
      if (mounted) {
        setState(() {
          _isSending = false;
          _selectedContact = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Échec du transfert du message'),
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
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transférer à',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      if (_sentContacts.isNotEmpty)
                        Text(
                          '${_sentContacts.length} envoyé${_sentContacts.length > 1 ? 's' : ''}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.secondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                    ],
                  ),
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
                              final isSent = _sentContacts.contains(contact);
                              final isLoading =
                                  _selectedContact == contact && _isSending;

                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSent
                                        ? AppTheme.secondaryColor
                                            .withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSent
                                        ? Border.all(
                                            color: AppTheme.secondaryColor,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: widget.isTransferMode && !isSent
                                          ? () => _selectContact(contact)
                                          : null,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: ContactWidget(
                                                contact: contact,
                                              ),
                                            ),
                                            if (widget.isTransferMode) ...[
                                              const SizedBox(width: 12),
                                              if (isSent)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppTheme.secondaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.check_circle,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Envoyé',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else if (isLoading)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  child: const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                        AppTheme.primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              else
                                                Container(
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                      colors: [
                                                        AppTheme.primaryColor,
                                                        AppTheme.secondaryColor,
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: _isSending
                                                          ? null
                                                          : () =>
                                                              _selectContact(
                                                                  contact),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 16,
                                                          vertical: 8,
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons.send,
                                                              color:
                                                                  Colors.white,
                                                              size: 18,
                                                            ),
                                                            const SizedBox(
                                                                width: 6),
                                                            Text(
                                                              'Envoyer',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ],
                                        ),
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

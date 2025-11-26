import 'package:flutter/material.dart';
import 'package:mini_social_network/models/group_message.dart';
import 'package:mini_social_network/services/discu_message_service.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';
import '../services/discu_group_service.dart';
import 'package:mini_social_network/utils/screen_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/contact_widget.dart';

class ContaScreen extends StatefulWidget {
  final bool isTransferMode;
  final String? messageId;
  final String? groupId;

  const ContaScreen({
    super.key,
    this.isTransferMode = false,
    this.messageId,
    this.groupId,
  });

  @override
  _ContaScreenState createState() => _ContaScreenState();
}

class _ContaScreenState extends State<ContaScreen>
    with SingleTickerProviderStateMixin {
  final ContactService _contactService = ContactService();
  final MessageService _messageService = MessageService();
  final GroupChatService _groupService = GroupChatService();
  final List<Contact> _contacts = [];
  final List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  final ScreenManager _screenManager = ScreenManager();

  bool _isProcessing = false;
  bool _isInitialLoading = true;
  bool _isSilentLoading = false;
  Contact? _selectedContact;
  final List<Contact> _processedContacts = [];
  List<Group> groupes = [];

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
    // ✅ 1. Enregistrer ce state dans le ScreenManager
    _screenManager.registerContactScreen(this);

    // ✅ 2. Mettre à jour l'écran actuel
    CurrentScreenManager.updateCurrentScreen('contact');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    CurrentScreenManager.clear();
    _screenManager.unregisterContactScreen();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      List<Contact> contacts;

      if (widget.isTransferMode) {
        // Mode transfert de message
        contacts = await _contactService.getContacts();
      } else {
        // Mode ajout de membre au groupe
        contacts = await _contactService.getNonMembre(widget.groupId!);
      }

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
      List<Contact> contacts;

      if (widget.isTransferMode) {
        contacts = await _contactService.getContacts();
      } else {
        contacts = await _contactService.getNonMembre(widget.groupId!);
      }

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

  Future<void> _handleContactAction(Contact contact) async {
    setState(() {
      _isProcessing = true;
      _selectedContact = contact;
    });

    try {
      if (widget.isTransferMode) {
        // Mode transfert de message
        if (contact.type == 'groupe') {
          await _messageService.transferMessageGroupe(
              contact.id, widget.messageId!);
        } else {
          await _messageService.transferMessage(contact.id, widget.messageId!);
        }

        if (mounted) {
          setState(() {
            _processedContacts.add(contact);
            _isProcessing = false;
            _selectedContact = null;
          });

          _showSuccessSnackBar('Message transféré à ${contact.nom}');
        }
      } else {
        // Mode ajout de membre au groupe
        final groupe =
            await _groupService.addMemberToGroup(widget.groupId!, contact.id);

        if (mounted) {
          setState(() {
            _processedContacts.add(contact);
            groupes.add(groupe);
            _isProcessing = false;
            _selectedContact = null;
          });

          _showSuccessSnackBar('${contact.nom} a été ajouté au groupe');
        }
      }
    } catch (e) {
      print('❌ Failed to process action: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _selectedContact = null;
        });

        _showErrorSnackBar(widget.isTransferMode
            ? 'Échec du transfert du message'
            : 'Échec de l\'ajout au groupe');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
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

  void _goBack() {
    if (widget.isTransferMode) {
      Navigator.pop(context);
    } else {
      Navigator.pop(context, groupes.isNotEmpty ? groupes.last : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
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
                      onPressed: _goBack,
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isTransferMode
                              ? 'Transférer à'
                              : 'Ajouter des membres',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        if (_processedContacts.isNotEmpty)
                          Text(
                            widget.isTransferMode
                                ? '${_processedContacts.length} envoyé${_processedContacts.length > 1 ? 's' : ''}'
                                : '${_processedContacts.length} ajouté${_processedContacts.length > 1 ? 's' : ''}',
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
                                final isProcessed =
                                    _processedContacts.contains(contact);
                                final isLoading = _selectedContact == contact &&
                                    _isProcessing;

                                return FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isProcessed
                                          ? AppTheme.secondaryColor
                                              .withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: isProcessed
                                          ? Border.all(
                                              color: AppTheme.secondaryColor,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: !isProcessed
                                            ? () =>
                                                _handleContactAction(contact)
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
                                              const SizedBox(width: 12),
                                              _buildActionButton(
                                                isProcessed,
                                                isLoading,
                                                contact,
                                              ),
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
      ),
    );
  }

  Widget _buildActionButton(bool isProcessed, bool isLoading, Contact contact) {
    if (isProcessed) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              widget.isTransferMode ? 'Envoyé' : 'Ajouté',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
              AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing ? null : () => _handleContactAction(contact),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isTransferMode ? Icons.send : Icons.person_add,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isTransferMode ? 'Envoyer' : 'Ajouter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';

// Provider pour le service de contacts
final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});

// State pour gérer les contacts
class ContactState {
  final List<Contact> contacts;
  final bool isLoading;
  final String? error;

  ContactState({
    this.contacts = const [],
    this.isLoading = false,
    this.error,
  });

  ContactState copyWith({
    List<Contact>? contacts,
    bool? isLoading,
    String? error,
  }) {
    return ContactState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier pour gérer la logique des contacts
class ContactNotifier extends StateNotifier<ContactState> {
  final ContactService _contactService;

  ContactNotifier(this._contactService) : super(ContactState(isLoading: true)) {
    loadContacts();
  }

  Future<void> loadContacts() async {
    state = state.copyWith(isLoading: true);
    try {
      final contacts = await _contactService.getContacts();
      state = state.copyWith(contacts: contacts, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load contacts: $e',
        isLoading: false,
      );
    }
  }

  Future<void> reload() async {
    await loadContacts();
  }

  Future<String?> createGroup(List<String> userIds, String groupName) async {
    try {
      final groupId = await _contactService.createGroup(userIds, groupName);
      await reload(); // Recharger la liste après création
      return groupId;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create group: $e');
      return null;
    }
  }
}

// Provider principal pour les contacts
final contactProvider =
    StateNotifierProvider<ContactNotifier, ContactState>((ref) {
  final service = ref.watch(contactServiceProvider);
  return ContactNotifier(service);
});

// Provider pour la recherche de contacts
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider pour les contacts filtrés
final filteredContactsProvider = Provider<List<Contact>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final contactState = ref.watch(contactProvider);

  if (query.isEmpty) {
    return contactState.contacts;
  }

  return contactState.contacts.where((contact) {
    return contact.nom.toLowerCase().contains(query.toLowerCase());
  }).toList();
});

// Provider pour les contacts sélectionnés
final selectedContactsProvider = StateProvider<Set<Contact>>((ref) => {});

// Provider pour savoir si on est en mode sélection
final isSelectionModeProvider = Provider<bool>((ref) {
  return ref.watch(selectedContactsProvider).isNotEmpty;
});

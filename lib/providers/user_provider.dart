import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Provider pour le stockage sécurisé
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Provider pour l'ID de l'utilisateur courant
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  String? user = await storage.read(key: 'user');
  return user?.replaceAll('"', '').trim();
});

// Provider synchrone qui écoute le FutureProvider
final currentUserIdSyncProvider = Provider<String?>((ref) {
  return ref.watch(currentUserIdProvider).value;
});

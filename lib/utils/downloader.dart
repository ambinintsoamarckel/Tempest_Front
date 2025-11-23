// lib/utils/downloader.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Télécharge un fichier depuis une URL et le sauvegarde dans le stockage externe
///
/// Retourne le chemin complet du fichier téléchargé
/// Lance une exception en cas d'erreur
Future<String> downloadFile(String url, String type) async {
  // 1. Vérifier et demander la permission
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }

  if (!status.isGranted) {
    throw Exception('Permission de stockage refusée');
  }

  // 2. Obtenir le répertoire de téléchargement
  final directory = await getExternalStorageDirectory();
  if (directory == null) {
    throw Exception('Impossible d\'obtenir le répertoire de stockage');
  }

  // 3. Créer le dossier spécifique pour le type de fichier
  final downloadDirectory = Directory('${directory.path}/houatsapy/$type');
  if (!await downloadDirectory.exists()) {
    await downloadDirectory.create(recursive: true);
  }

  // 4. Extraire le nom du fichier depuis l'URL
  final fileName = url.split('/').last;
  final filePath = '${downloadDirectory.path}/$fileName';
  final file = File(filePath);

  // 5. Télécharger le fichier
  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    throw Exception('Échec du téléchargement (Code ${response.statusCode})');
  }

  // 6. Sauvegarder le fichier
  await file.writeAsBytes(response.bodyBytes);

  print('✅ Fichier téléchargé : $filePath');

  // 7. Retourner le chemin complet
  return filePath;
}

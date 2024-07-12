import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

Future<void> downloadFile(ScaffoldMessengerState scaffoldMessenger, String url, String type) async {
  // Demande la permission de stockage
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }

  if (status.isGranted) {
    try {
      // Obtenir le répertoire de stockage externe
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception("Impossible d'obtenir le répertoire de stockage externe.");
      }

      final downloadDirectory = Directory('${directory.path}/houatsapy/$type');

      if (!await downloadDirectory.exists()) {
        await downloadDirectory.create(recursive: true);
      }

      final fileName = url.split('/').last;
      final file = File('${downloadDirectory.path}/$fileName');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);

        print('Fichier téléchargé à: ${file.path}');

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('$type téléchargé sous le nom $fileName dans ${downloadDirectory.path}')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Échec du téléchargement de $type')),
        );
      }
    } catch (e) {
      print('Erreur lors du téléchargement : $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement : $e')),
      );
    }
  } else {
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Permission de stockage refusée')),
    );
  }
}

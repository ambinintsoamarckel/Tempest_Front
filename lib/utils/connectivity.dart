import 'dart:io';

Future<bool> checkConnectivity() async {
  try {
    // Utilise un nom d'hôte connu et fiable pour une vérification générale
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  }
}

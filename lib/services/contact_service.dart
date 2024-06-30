import 'package:dio/dio.dart';
import '../models/contact.dart';
import '../network/network_config.dart';

class ContactService {
  final Dio dio = NetworkConfig().client;

  Future<List<Contact>> getContacts() async {
    try {
      final response = await dio.get('/utilisateurs');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        List<Contact> contacts = data.map((json) => Contact.fromJson(json)).toList();
        return contacts;
      } else {
        throw Exception('Failed to load contacts');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

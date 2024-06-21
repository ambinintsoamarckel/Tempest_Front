import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contact.dart';

class ContactService {
  final String baseUrl;

  ContactService({required this.baseUrl});

  Future<Contact?> createContact(Map<String, dynamic> contactData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contacts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(contactData),
    );

    if (response.statusCode == 201) {
      return Contact.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create contact');
    }
  }

  Future<Contact?> getContactById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/contacts/$id'));

    if (response.statusCode == 200) {
      return Contact.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load contact');
    }
  }

  Future<Contact?> updateContact(String id, Map<String, dynamic> contactData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/contacts/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(contactData),
    );

    if (response.statusCode == 200) {
      return Contact.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update contact');
    }
  }

  Future<void> deleteContact(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/contacts/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete contact');
    }
  }

  Future<List<Contact>> getContacts() async {
    final response = await http.get(Uri.parse('$baseUrl/contacts'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Contact> contacts = body.map((dynamic item) => Contact.fromJson(item)).toList();
      return contacts;
    } else {
      throw Exception('Failed to load contacts');
    }
  }
}

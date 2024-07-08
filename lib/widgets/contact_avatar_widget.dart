import 'package:flutter/material.dart';
import '../models/contact.dart';

class ContactAvatarWidget extends StatelessWidget {
  final Contact contact;

  const ContactAvatarWidget({Key? key, required this.contact}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 24.0, // Taille de l'avatar
              backgroundImage: contact.photo != null
                  ? NetworkImage(contact.photo!)
                  : null,
              child: contact.photo == null
                  ? const Icon(Icons.person, size: 24.0)
                  : null,
            ),
            if (contact.presence == 'actif')
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4), // Espacement entre l'avatar et le nom
        Flexible(
          child: Text(
            contact.nom,
            style: TextStyle(fontSize: 14, color: Colors.white), // Taille de la police
            overflow: TextOverflow.ellipsis, // Ajoutez l'overflow pour éviter le débordement
          ),
        ),
      ],
    );
  }
}

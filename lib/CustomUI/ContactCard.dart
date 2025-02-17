import 'package:chatapp/Model/ChatModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({Key? key, required this.contact}) : super(key: key);
  final ChatModel contact;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 53,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: Colors.blueGrey[200],
              backgroundImage: contact.icon != null
                  ? (contact.icon!.startsWith('http')
                  ? NetworkImage(contact.icon!) as ImageProvider<Object>?
                  : AssetImage("assets/person.svg") as ImageProvider<Object>?)
                  : const AssetImage("assets/person.svg") as ImageProvider<Object>?,
              child: contact.icon == null || !contact.icon!.startsWith('http')
                  ? SvgPicture.asset(
                "assets/person.svg",
                color: Colors.white,
                height: 30,
                width: 30,
              )
                  : null,
            ),
            // Handling potential null value for contact.select
            (contact.select ?? false) // Using null-aware operator and defaulting to false
                ? Positioned(
              bottom: 4,
              right: 5,
              child: CircleAvatar(
                backgroundColor: Colors.teal,
                radius: 11,
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            )
                : Container(),
          ],
        ),
      ),
      title: Text(
        contact.name ?? "No Name", // Provide a default value
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contact.uid ?? "No ID",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            contact.lastSeen != null && contact.lastSeen!.isNotEmpty
                ? "Last seen: ${contact.lastSeen}"
                : contact.status ?? "No Status", // Provide a default value
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String profileImageUrl;

  const UserCard({
    Key? key,
    required this.name,
    required this.email,
    required this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(profileImageUrl),
        ),
        title: Text(name),
        subtitle: Text(email),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          // Handle card tap
        },
      ),
    );
  }
}
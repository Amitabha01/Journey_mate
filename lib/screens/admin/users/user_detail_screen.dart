import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/admin_service.dart';

class UserDetailScreen extends StatelessWidget {
  final UserModel user;
  final AdminService _adminService = AdminService();

  UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User: ${user.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            const SizedBox(height: 10),
            Text('Verified: ${user.isVerified}'),
            Text('Blocked: ${user.isBlocked}'),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _adminService.verifyUser(user.uid);
                    Navigator.pop(context);
                  },
                  child: const Text('Verify'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _adminService.blockUser(user.uid);
                    Navigator.pop(context);
                  },
                  child: const Text('Block'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Uploaded Documents:'),
            ...user.uploadedDocs.entries.map((doc) => ListTile(
                  title: Text(doc.key),
                  subtitle: Text(doc.value),
                  onTap: () {
                    // You can launch the document using url_launcher
                  },
                )),
          ],
        ),
      ),
    );
  }
}
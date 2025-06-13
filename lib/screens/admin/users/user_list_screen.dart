import 'package:flutter/material.dart';
import 'package:journey_mate_app_v1/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class UserListScreen extends StatelessWidget {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('All Users')),
      body: StreamBuilder<List<UserModel>>(
        stream: _adminService.getAllUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(user.isBlocked ? Icons.lock : Icons.lock_open),
                      onPressed: () => _adminService.blockUser(user.uid, !user.isBlocked),
                    ),
                    IconButton(
                      icon: Icon(user.isVerified ? Icons.verified : Icons.verified_outlined),
                      onPressed: () => _adminService.verifyUser(user.uid, !user.isVerified),
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to user detail screen
                },
              );
            },
          );
        },
      ),
    );
  }
}

class AdminService {
  final _db = FirebaseFirestore.instance;

  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => UserModel.fromFirestore(doc.data(), doc.id)).toList()
    );
  }

  Future<void> blockUser(String uid, bool block) async {
    await _db.collection('users').doc(uid).update({'isBlocked': block});
  }

  Future<void> verifyUser(String uid, bool verify) async {
    await _db.collection('users').doc(uid).update({'isVerified': verify});
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import '../../models/user_model.dart';

// class ProfileScreen extends StatelessWidget {
//   final UserModel user;
//   const ProfileScreen({super.key, required this.user});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Profile')),
//       body: Column(
//         children: [
//           Text('Name: ${user.name}'),
//           Text('Email: ${user.email}'),
//           Text('Verified: ${user.isVerified}'),
//           // Show uploaded documents, allow upload
//         ],
//       ),
//     );
//   }
// }

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(user?.email ?? 'No user email'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
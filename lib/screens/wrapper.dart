import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home/home_screen.dart';
import './auth/signin_page.dart'; // Replace with your actual SignInScreen file path

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Check if the user is logged in
    if (user != null) {
      return const HomeScreen(); // Navigate to HomeScreen if logged in
    } else {
      return const SigninPage(); // Navigate to SignInScreen if not logged in
    }
  }
}
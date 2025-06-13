import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/ride_model.dart';
import '../../screens/admin/rides/chat_screen.dart';


final userId = FirebaseAuth.instance.currentUser?.uid;

class RideDetailsScreen extends StatelessWidget {
  final RideModel ride;
  const RideDetailsScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ride Details')),
      body: Column(
        children: [
          Text('From: ${ride.origin}'),
          Text('To: ${ride.destination}'),
          Text('Date: ${ride.journeyDate}'),
          Text('Driver: ${ride.driverId}'),
          // Add map and live location widgets here
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatScreen(rideId: ride.rideId)),
              );
            },
            child: const Text('Open Chat'),
          ),
        ],
      ),
    );
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final bool isVerified;
  final bool isBlocked;
  final Map<String, String> uploadedDocs;
  final String? currentRideId;
  final Map<String, double>? lastLocation;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.isVerified,
    required this.isBlocked,
    required this.uploadedDocs,
    this.currentRideId,
    this.lastLocation,
  });

  static UserModel fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      isVerified: data['isVerified'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
      uploadedDocs: Map<String, String>.from(data['uploadedDocs'] ?? {}),
      currentRideId: data['currentRideId'],
      lastLocation: data['lastLocation'] != null
          ? Map<String, double>.from(data['lastLocation'])
          : null,
    );
  }
}
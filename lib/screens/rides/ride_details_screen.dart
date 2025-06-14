import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../models/ride_model.dart';
import '../../services/chat_service.dart';

class RideDetailsScreen extends StatelessWidget {
  final RideModel ride;
  const RideDetailsScreen({super.key, required this.ride});

  Future<String> _fetchDriverName(String driverId) async {
    try {
      // Fetch driver name from Realtime Database
      final DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(driverId);
      final DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        return snapshot.child('userName').value as String? ?? 'Unknown Driver';
      } else {
        print('Driver document does not exist for driverId: $driverId');
        return 'Unknown Driver';
      }
    } catch (e) {
      print('Error fetching driver name: $e');
      return 'Unknown Driver';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'From: ${ride.origin}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'To: ${ride.destination}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Date: ${ride.journeyDate}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    FutureBuilder<String>(
                      future: _fetchDriverName(ride.driverId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text(
                            'Driver: Loading...',
                            style: TextStyle(fontSize: 16),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text(
                            'Driver: Unknown',
                            style: TextStyle(fontSize: 16),
                          );
                        }
                        return Text(
                          'Driver Name: ${snapshot.data}',
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                    Text(
                      'Driver ID: ${ride.driverId}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final chatService = ChatService();
                  final canChat = await chatService.canChat(ride.rideId);

                  if (!canChat) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Chat is closed for this ride.")),
                    );
                    return;
                  }

                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  if (currentUserId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You must be logged in to access the chat.")),
                    );
                    return;
                  }

                  // Dynamically check if the current user is a participant in the ride
                  final isParticipant = await chatService.isParticipant(ride.rideId, currentUserId);
                  if (!isParticipant) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to access this chat.")),
                    );
                    return;
                  }

                  // Navigate to the chat screen and pass the rideId
                  Navigator.pushNamed(context, '/chatscreen', arguments: ride.rideId);
                },
                child: const Text(
                  'Open Chat',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
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
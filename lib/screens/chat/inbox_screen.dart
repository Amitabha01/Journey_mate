import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:journey_mate_app_v1/screens/chat/chat_screen.dart'; // Import the ChatScreen

class InboxScreen extends StatelessWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text("You must be logged in to view your inbox."),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inbox"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No conversations found."));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final rideId = chat['rideId'] ?? 'Unknown Ride';
              final lastMessage = chat['lastMessage'] ?? 'No messages yet';

              return ListTile(
                title: Text(rideId),
                subtitle: Text(lastMessage),
                onTap: () async {
                  final canChat = await _canChat(rideId);
                  if (canChat) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(rideId: rideId),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Cannot open chat for this ride.")),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _canChat(String rideId) async {
    final rideDoc = await FirebaseFirestore.instance.collection('rides').doc(rideId).get();

    if (!rideDoc.exists) {
      print('Ride does not exist.');
      return false; // Ride does not exist
    }

    final rideData = rideDoc.data();
    if (rideData == null) {
      print('Ride data is null.');
      return false;
    }

    final journeyDate = DateTime.parse(rideData['journeyDate']);
    final now = DateTime.now();

    // Debugging: Print the journey date and current date
    print('Journey Date: $journeyDate, Current Date: $now');

    // Check if the ride is expired
    return journeyDate.isAfter(now); // Chat is active if the ride is not expired
  }
}

class ChatScreen extends StatelessWidget {
  final String rideId;

  const ChatScreen({Key? key, required this.rideId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat for Ride $rideId'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Text('Chat interface for ride $rideId'),
      ),
    );
  }
}
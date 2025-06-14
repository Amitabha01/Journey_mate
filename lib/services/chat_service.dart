import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  Stream<List<ChatMessage>> getMessages(String rideId) {
    return _db
        .collection('chats')
        .doc(rideId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data())).toList());
  }

  Future<void> sendMessage(String rideId, ChatMessage message) async {
    await _db
        .collection('chats')
        .doc(rideId)
        .collection('messages')
        .add(message.toMap());
  }

  Future<bool> canChat(String rideId) async {
    final rideDoc = await _db.collection('rides').doc(rideId).get();

    if (!rideDoc.exists) {
      return false; // Ride does not exist
    }

    final rideData = rideDoc.data();
    if (rideData == null) {
      return false; // Ride data is null
    }

    final journeyDate = DateTime.parse(rideData['journeyDate']);
    final now = DateTime.now();

    // Check if the ride is expired
    return journeyDate.isAfter(now); // Chat is active if the ride is not expired
  }

  Future<bool> isParticipant(String rideId, String userId) async {
    final rideDoc = await _db.collection('rides').doc(rideId).get();

    if (!rideDoc.exists) {
      return false; // Ride does not exist
    }

    final rideData = rideDoc.data();
    if (rideData == null) {
      return false; // Ride data is null
    }

    // Check if the user is either the driver or the booker
    final driverId = rideData['driverId'];
    final bookerId = rideData['bookerId']; // Optional field, may not exist
    return driverId == userId || bookerId == userId;
  }
}
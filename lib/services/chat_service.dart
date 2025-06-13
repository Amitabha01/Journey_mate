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
    final doc = await _db.collection('chats').doc(rideId).get();
    return doc.exists && doc.data()?['rideStatus'] == 'active';
  }
}
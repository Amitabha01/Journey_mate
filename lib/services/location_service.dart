import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final _db = FirebaseFirestore.instance;

  Future<void> updateUserLocation(String uid, double lat, double lng) async {
    await _db.collection('users').doc(uid).update({
      'lastLocation': {'lat': lat, 'lng': lng},
      'lastLocationUpdated': DateTime.now().toIso8601String(),
    });
  }

  Stream<Map<String, dynamic>?> getUserLocationStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
      (doc) => doc.data()?['lastLocation'] as Map<String, dynamic>?,
    );
  }
}
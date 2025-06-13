import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> setData(String path, Map<String, dynamic> data) async {
    await _db.doc(path).set(data);
  }

  Stream<DocumentSnapshot> streamDocument(String path) {
    return _db.doc(path).snapshots();
  }

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _db.doc(path).update(data);
  }
}
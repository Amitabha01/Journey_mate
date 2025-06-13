import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_core/firebase_core.dart';

import '../models/user_model.dart';


class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<UserModel>> fetchAllUsers() async {
    var snapshot = await _db.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> blockUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isBlocked': true});
  }

  Future<void> unblockUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isBlocked': false});
  }

  Future<void> verifyUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isVerified': true});
  }

  Future<void> unverifyUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isVerified': false});
  }
}
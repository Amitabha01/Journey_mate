import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadDocument(String uid, File file, String docType) async {
    final ref = _storage.ref().child('user_docs/$uid/$docType');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
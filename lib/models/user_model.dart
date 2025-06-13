// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String name;
  final String email;
  final bool isVerified;
  final bool isBlocked;
  final Map<String, String> uploadedDocs; //{docType: url}
  final String? currentRideId; // New: current ride
  final Map<String, double>? lastLocation; // New: {lat, lng}


  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.isVerified = false,
    this.isBlocked = false,
    this.uploadedDocs = const {},
    this.currentRideId,
    this.lastLocation,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'],
    name: map['name'],
    email: map['email'],
    isVerified: map['isVerified'] ?? false,
    isBlocked: map['isBlocked'] ?? false,
    uploadedDocs: Map<String, String>.from(map['uploadedDocs'] ?? {}),
    currentRideId: map['currentRideId'],
    lastLocation: map['lastLocation'] != null
        ? Map<String, double>.from(map['lastLocation'])
        : null,
  );

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'uploadedDocs': uploadedDocs,
      'currentRideId': currentRideId,
      'lastLocation': lastLocation,
    };
  }

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

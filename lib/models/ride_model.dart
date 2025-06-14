import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';

final logger = Logger();


class RideModel {
  final String rideId;
  final String driverId;
  final List<String> passengerIds;
  final String origin;
  final String destination;
  final DateTime journeyDate;
  final String journeyTime;
  final double price;
  final int seatsAvailable;
  final double distance;
  final double originLng;
  final double originLat;
  final double destinationLng;
  final double destinationLat;
  final String creatorId;
  String driverName;
  String? label;

  RideModel({
    required this.rideId,
    required this.driverId,
    required this.passengerIds,
    required this.origin,
    required this.destination,
    required this.journeyDate,
    required this.journeyTime,
    required this.price,
    required this.seatsAvailable,
    required this.distance,
    required this.driverName,
    required this.originLng,
    required this.originLat,
    required this.destinationLng,
    required this.destinationLat,
    required this.creatorId,
    this.label,
  });

  static Future<RideModel> fromFirestore(DocumentSnapshot doc) async {
  final data = doc.data() as Map<String, dynamic>?;

  if (data == null) {
    throw Exception('Ride data is null');
  }

  String driverName = data['driverName'] ?? 'Unknown Driver';
  
  final driverId = data['driverId'] ?? '';

  try {
    final driverRef = FirebaseDatabase.instance.ref().child('users').child(driverId);
    final driverSnapshot = await driverRef.get();
    if (driverSnapshot.exists) {
      driverName = driverSnapshot.child('userName').value as String? ?? 'Unknown Driver';
    }
  } catch (e) {
    print('Error fetching driver name: $e');
  }

  return RideModel(
    rideId: doc.id,
    driverId: driverId,
    passengerIds: List<String>.from(data['passengerIds'] ?? []),
    origin: data['origin'] ?? 'Unknown',
    destination: data['destination'] ?? 'Unknown',
    journeyDate: (data['journeyDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    journeyTime: data['journeyTime'] ?? '00:00',
    price: (data['price'] as num?)?.toDouble() ?? 0.0,
    seatsAvailable: data['seatsAvailable'] ?? 0,
    distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
    driverName: driverName,
    originLng: (data['originLng'] as num?)?.toDouble() ?? 0.0,
    originLat: (data['originLat'] as num?)?.toDouble() ?? 0.0,
    destinationLng: (data['destinationLng'] as num?)?.toDouble() ?? 0.0,
    destinationLat: (data['destinationLat'] as num?)?.toDouble() ?? 0.0,
    creatorId: data['creatorId'] ?? '',
  );
}

  Map<String, dynamic> toMap() => {
        'rideId': rideId,
        'driverId': driverId,
        'passengerIds': passengerIds,
        'origin': origin,
        'destination': destination,
        'journeyDate': Timestamp.fromDate(journeyDate), // Convert DateTime to Firestore Timestamp
        'journeyTime': journeyTime,
        'price': price,
        'seatsAvailable': seatsAvailable, 
        'distance': distance, // Ensureing distance is included
        'driverName': driverName, // Ensure driverName is included
        'originLng': originLng,
        'originLat': originLat,
        'destinationLng': destinationLng,
        'destinationLat': destinationLat,
        'creatorId': creatorId,

      };

      // Fetch the driver's name dynamically from Firestore
  static Future<String> fetchDriverName(String driverId) async {
    try {
      final driverDoc = await FirebaseFirestore.instance.collection('users').doc(driverId).get();
      final driverName = driverDoc.data()?['name'] ?? 'Unknown Driver7';
      return driverName;
    } catch (e) {
      return 'Unknown Driver6';
    }
  }

      @override
      String toString() {
        return 'RideModel{rideId: $rideId, driverId: $driverId, passengerIds: $passengerIds, origin: $origin, destination: $destination, journeyDate: $journeyDate, journeyTime: $journeyTime, price: $price, seatsAvailable: $seatsAvailable}';
      }

      // Add the fromMap factory constructor
  factory RideModel.fromMap(Map<String, dynamic> map) {
    return RideModel(
      rideId: map['rideId'] ?? '',
      driverId: map['driverId'] ?? '',
      passengerIds: List<String>.from(map['passengerIds'] ?? []),
      origin: map['origin'] ?? 'Unknown',
      destination: map['destination'] ?? 'Unknown',
      journeyDate: (map['journeyDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      journeyTime: map['journeyTime'] ?? '00:00',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      seatsAvailable: map['seatsAvailable'] ?? 0,
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      driverName: map['driverName'] ?? 'Unknown Driver',
      originLng: (map['originLng'] as num?)?.toDouble() ?? 0.0,
      originLat: (map['originLat'] as num?)?.toDouble() ?? 0.0,
      destinationLng: (map['destinationLng'] as num?)?.toDouble() ?? 0.0,
      destinationLat: (map['destinationLat'] as num?)?.toDouble() ?? 0.0,
      creatorId: map['creatorId'] ?? '',
      label: map['label'],
    );
  }
}
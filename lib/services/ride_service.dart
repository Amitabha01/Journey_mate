import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/ride_model.dart';


class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createRide(RideModel ride, double originLat, double originLng, double destinationLat, double destinationLng) async {
    try {
      print("Attempting to write ride to Firestore...");

      await _firestore.collection('rides').doc(ride.rideId).set(ride.toMap());

      print("Ride successfully written to Firestore.");

    } catch (e) {
      print("Error writing ride to Firestore: $e");

      throw Exception('Failed to create ride: $e');
    }
  }

  Future<void> joinRide(String rideId, String userId) async {
    await _firestore.collection('rides').doc(rideId).update({
      'passengerIds': FieldValue.arrayUnion([userId])
    });
  }

  Future<double> calculateDistance(double startLat, double startLng, double endLat, double endLng) async {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000; // Convert meters to kilometers
  }

  Stream<List<RideModel>> getAvailableRides() async* {
    final ridesSnapshot = await _firestore.collection('rides').get();

    final rides = await Future.wait(ridesSnapshot.docs.map((doc) async {
      final rideData = doc.data();
      String driverName = rideData['driverName'] ?? 'Unknown Driver';

      // If driverName is missing or invalid, fetch it from Realtime Database
      if (driverName == 'Unknown Driver') {
        final driverId = rideData['driverId'];
       try {
          final driverRef = FirebaseDatabase.instance.ref().child('users').child(driverId);
          final driverSnapshot = await driverRef.get();
          if (driverSnapshot.exists) {
            driverName = driverSnapshot.child('userName').value as String? ?? 'Unknown Driver';
          }
        } catch (e) {
          print("Error fetching driver name from Realtime Database: $e");
        }
      }

      return RideModel(
        rideId: doc.id,
        driverId: rideData['driverId'],
        passengerIds: List<String>.from(rideData['passengerIds'] ?? []),
        origin: rideData['origin'],
        destination: rideData['destination'],
        originLat: (rideData['originLat'] as num?)?.toDouble() ?? 0.0,
        originLng: (rideData['originLng'] as num?)?.toDouble() ?? 0.0,
        destinationLat: (rideData['destinationLat'] as num?)?.toDouble() ?? 0.0,
        destinationLng: (rideData['destinationLng'] as num?)?.toDouble() ?? 0.0,
        journeyDate: (rideData['journeyDate'] as Timestamp).toDate(),
        journeyTime: rideData['journeyTime'] ?? 'Unknown Time',
        seatsAvailable: rideData['seatsAvailable'],
        price: rideData['price'],
        distance: rideData['distance'],
        driverName: driverName, // Include the driver's full name
      );
    }).toList());

    yield rides;
  }
}

class YourRidesScreen extends StatelessWidget {
  final List<RideModel> rides;

  const YourRidesScreen({Key? key, required this.rides}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // logger.i('Displaying rides: $rides');
    return Scaffold(
      appBar: AppBar(title: const Text('Your Rides')),
      body: rides.isEmpty
          ? const Center(child: Text('No rides found.'))
          : ListView.builder(
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final ride = rides[index];
                return ListTile(
                  title: Text('${ride.origin} ➝ ${ride.destination}'),
                  subtitle: Text('${ride.journeyDate} at ${ride.journeyTime}'),
                );
              },
            ),
    );
  }
}
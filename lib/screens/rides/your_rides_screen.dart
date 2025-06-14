import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ride_model.dart';
import 'ride_details_screen.dart';

class YourRidesScreen extends StatelessWidget {
  const YourRidesScreen({Key? key}) : super(key: key);

  Future<List<RideModel>> _fetchCreatedRides(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('rides')
        .where('driverId', isEqualTo: userId)
        .get();

    final rides = snapshot.docs.map((doc) => RideModel.fromMap(doc.data())).toList();

    // Fetch confirmed bookings for each ride
    for (var ride in rides) {
      final confirmedSeatsSnapshot = await FirebaseFirestore.instance
          .collection('confirmedRides')
          .where('rideId', isEqualTo: ride.rideId)
          .get();

      final confirmedSeats = confirmedSeatsSnapshot.docs.length;

      // Calculate available seats
      final availableSeats = ride.seatsAvailable - confirmedSeats;

      // Update the ride label based on booking status
      if (confirmedSeats == 0) {
        ride.label = "Created";
      } else if (availableSeats > 0) {
        ride.label = "Available Seats: $availableSeats/${ride.seatsAvailable}";
      } else {
        ride.label = "Created | Booked";
      }
    }

    return rides;
  }

  Future<List<RideModel>> _fetchConfirmedRides(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('confirmedRides')
        .where('passengerId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => RideModel.fromMap(doc.data())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Rides"),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<List<RideModel>>>(
        future: Future.wait([
          _fetchCreatedRides(userId),
          _fetchConfirmedRides(userId),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No rides found."));
          }

          final createdRides = snapshot.data![0];
          final confirmedRides = snapshot.data![1];

          return ListView(
            children: [
              if (createdRides.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Created Rides", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...createdRides.map((ride) => _buildRideTile(context, ride, ride.label ?? "Created")),
              ],
              if (confirmedRides.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Confirmed Rides", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...confirmedRides.map((ride) => _buildRideTile(context, ride, "Confirmed")),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildRideTile(BuildContext context, RideModel ride, String type) {
    String subtitleText;

    if (type == "Confirmed") {
      // Show passenger count for confirmed rides
      subtitleText =
          '${ride.journeyDate.toLocal().toString().split(" ")[0]} | ₹${ride.price} | $type | Passengers: ${ride.seatsAvailable}';
    } else {
      // Show total seats for created rides
      subtitleText =
          '${ride.journeyDate.toLocal().toString().split(" ")[0]} | ₹${ride.price} | $type | Total Seats: ${ride.seatsAvailable}';
    }

    return Card(
      child: ListTile(
        title: Text('${ride.origin} ➝ ${ride.destination}'),
        subtitle: Text(subtitleText),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideDetailsScreen(ride: ride),
            ),
          );
        },
      ),
    );
  }
}
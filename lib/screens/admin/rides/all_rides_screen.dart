import 'package:flutter/material.dart';
import '../../../widgets/ride_card.dart'; // Ensure this path is correct
import '../../../models/ride_model.dart';
import '../../../services/ride_service.dart';

class AllRidesScreen extends StatelessWidget {
  final RideService _rideService = RideService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Rides'),
      ),
      body: StreamBuilder<List<RideModel>>(
        stream: _rideService.getAvailableRides(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No rides available.'));
          }

          final rides = snapshot.data!;

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return RideCard(
                destination: ride.destination,
                date: ride.journeyDate.toLocal().toString().split(' ')[0],
                time: ride.journeyTime,
                driverName: ride.driverId, // Replace with driver name if available
                rideId: ride.rideId, // Pass the rideId
                driverId: ride.driverId, // Pass the driverId
              );
            },
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../models/ride_model.dart';

class YourRidesScreen extends StatelessWidget {
  final List<RideModel> rides;

  const YourRidesScreen({Key? key, required this.rides}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Rides"),
        backgroundColor: Colors.teal,
      ),
      body: rides.isEmpty
          ? const Center(child: Text("No rides found."))
          : ListView.builder(
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final ride = rides[index];
                return Card(
                  child: ListTile(
                    title: Text('${ride.origin} ➝ ${ride.destination}'),
                    subtitle: Text(
                      '${ride.journeyDate.toLocal().toString().split(" ")[0]} at ${ride.journeyTime} | ₹${ride.price} | Distance: ${ride.distance.toStringAsFixed(2)} km',
                    ),
                    trailing: Text('${ride.seatsAvailable} seats'),
                  ),
                );
              },
            ),
    );
  }
}
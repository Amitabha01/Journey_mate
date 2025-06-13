import 'package:flutter/material.dart';
import '../../models/ride_model.dart';

class ConfirmBookingScreen extends StatelessWidget {
  final RideModel ride;

  const ConfirmBookingScreen({Key? key, required this.ride}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Booking"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("From: ${ride.origin}", style: const TextStyle(fontSize: 18)),
            Text("To: ${ride.destination}", style: const TextStyle(fontSize: 18)),
            Text("Date: ${ride.journeyDate.toLocal().toString().split(' ')[0]}", style: const TextStyle(fontSize: 18)),
            Text("Price: ₹${ride.price}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle booking confirmation logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("Confirm Booking", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
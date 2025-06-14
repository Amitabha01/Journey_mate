import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ride_model.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final RideModel ride;
  final String currentUserId;

  const ConfirmBookingScreen({Key? key, required this.ride, required this.currentUserId}) : super(key: key);

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  bool _isProcessing = false; // To track if the button is being processed

  @override
  Widget build(BuildContext context) {
    bool isRideCreator = widget.ride.creatorId == widget.currentUserId;

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
            Text("From: ${widget.ride.origin}", style: const TextStyle(fontSize: 18)),
            Text("To: ${widget.ride.destination}", style: const TextStyle(fontSize: 18)),
            Text("Date: ${widget.ride.journeyDate.toLocal().toString().split(' ')[0]}", style: const TextStyle(fontSize: 18)),
            Text("Price: ₹${widget.ride.price}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isRideCreator || _isProcessing
                  ? null
                  : () async {
                      setState(() {
                        _isProcessing = true; // Disable the button
                      });

                      await _sendBookingRequest(context);

                      setState(() {
                        _isProcessing = false; // Re-enable the button
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Confirm Booking", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendBookingRequest(BuildContext context) async {
    print("Confirm Booking button clicked"); // Debug print

    // Simulate a delay for the booking process
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Add the booking to the 'confirmedRides' collection
      await FirebaseFirestore.instance.collection('confirmedRides').add({
        'rideId': widget.ride.rideId,
        'passengerId': widget.currentUserId,
        'driverId': widget.ride.creatorId,
        'origin': widget.ride.origin,
        'destination': widget.ride.destination,
        'journeyDate': widget.ride.journeyDate,
        'price': widget.ride.price,
        'status': 'confirmed', // Status is now 'confirmed'
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride confirmed successfully!")),
      );

      print("Ride confirmed successfully!"); // Debug print

      // Navigate to the "Your Rides" section
      Navigator.pushNamed(context, '/yourrides');
    } catch (e) {
      print("Error confirming booking: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to confirm the booking.")),
      );
    }
  }
}

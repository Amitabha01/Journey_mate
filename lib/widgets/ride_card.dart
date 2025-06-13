import 'package:flutter/material.dart';
import '../services/ride_service.dart';



class RideCard extends StatelessWidget {
  final String destination;
  final String date;
  final String time;
  final String driverName;
  final String rideId;
  final String driverId;

  const RideCard({
    Key? key,
    required this.destination,
    required this.date,
    required this.time,
    required this.driverName,
    required this.rideId,
    required this.driverId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(destination),
        subtitle: Text('Date: $date\nTime: $time\nDriver: $driverName'),
        trailing: Icon(Icons.directions_car),
        onTap: () async{
          // Handle card tap
          final rideService = RideService();
          // TODO: Replace 'userId' with the actual user ID from your authentication logic
          final String userId = 'your_user_id_here';
          try {
            // Call the joinRide method when the card is tapped
            await rideService.joinRide(rideId, userId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully joined the ride!')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to join the ride: $e')),
            );
          }
        },
      ),
    );
  }
}
//import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../methods/common_connection_methods.dart';
import '../../widgets/loading_dialouge.dart';
import '../../services/ride_service.dart';
import '../../models/ride_model.dart';

final String mapboxApiKey = dotenv.env["MAPBOX_ACCESS_TOKEN_KEY"] ?? "";
final logger = Logger();

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({Key? key}) : super(key: key);

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _passengerController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _driverPriceController = TextEditingController();

  List<dynamic> _originSuggestions = [];
  List<dynamic> _destinationSuggestions = [];

  LatLng? _originLatLng;
  LatLng? _destinationLatLng;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  double? _estimatedPrice;

  User? _currentUser;
  bool _isCreatingRide = false; // Prevent multiple ride creations


  @override
  void initState() {
    super.initState();
    _checkUserAuthentication();

    // Add listener to passenger controller
    _passengerController.addListener(() {
      _calculateEstimatedPrice();
    });
  }

  @override
  void dispose() {
    // Remove listener to avoid memory leaks
    _passengerController.removeListener(() {
      _calculateEstimatedPrice();
    });
    _passengerController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    _driverPriceController.dispose();
    super.dispose();
  }

  Future<void> _checkUserAuthentication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _fetchMapboxSuggestions(String input, bool isOrigin) async {
    final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$input.json?access_token=$mapboxApiKey&autocomplete=true&limit=5');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List;

        setState(() {
          if (isOrigin) {
            _originSuggestions = features;
          } else {
            _destinationSuggestions = features;
          }
        });
      } else {
        logger.e('Failed to fetch suggestions: ${response.body}');
      }
    } catch (e) {
      logger.e('Error fetching suggestions: $e');
    }
  }

  void _onSuggestionTap(dynamic suggestion, bool isOrigin) {
    final coords = suggestion['geometry']['coordinates'];
    final name = suggestion['place_name'];

    setState(() {
      if (isOrigin) {
        _originController.text = name;
        _originLatLng = LatLng(coords[1], coords[0]);
        _originSuggestions.clear();
      } else {
        _destinationController.text = name;
        _destinationLatLng = LatLng(coords[1], coords[0]);
        _destinationSuggestions.clear();
      }
      _calculateEstimatedPrice();
    });
  }

  void _calculateEstimatedPrice() {
    if (_originLatLng != null && _destinationLatLng != null) {
      final distance = const Distance().as(
        LengthUnit.Kilometer,
        _originLatLng!,
        _destinationLatLng!,
      );

      // Get the number of passengers
      final int passengers = int.tryParse(_passengerController.text) ?? 1;

      setState(() {
        // Update estimated price based on distance and passengers
        _estimatedPrice = distance * 0.5 * passengers; // Assume $0.5 per km per passenger
        _priceController.text = _estimatedPrice!.toStringAsFixed(2);
      });
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _createRide() async {

    if (_isCreatingRide) return; // Prevent multiple taps

    setState(() {
      _isCreatingRide = true; // Set loading state to true
    });

    try {

      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to create a ride')),
        );
        return;
      }

      if (_originLatLng == null || _destinationLatLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select valid origin and destination')),
        );
        return;
      }

      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid date and time')),
        );
        return;
      }

      if (_passengerController.text.isEmpty || int.tryParse(_passengerController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid number of passengers')),
        );
        return;
      }

      final int passengers = int.parse(_passengerController.text);
        if (passengers < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Number of passengers must be 1 or more')),
          );
        return;
      }

      double finalPrice;
      if (_driverPriceController.text.isNotEmpty &&
        double.tryParse(_driverPriceController.text) != null) {

          finalPrice = double.parse(_driverPriceController.text);

        } else if (_estimatedPrice != null) {

        finalPrice = _estimatedPrice!;

      } else {

        ScaffoldMessenger.of(context).showSnackBar(

           const SnackBar(content: Text('Please provide a valid price')),

        );

        return;
      }

      final rideId = FirebaseFirestore.instance.collection('rides').doc().id; // Generate a unique ride ID

      // Fetch driver's name from Firestore
       String driverName = 'Unknown Driver';
  
      try {

        final driverRef = FirebaseDatabase.instance.ref().child('users').child(_currentUser!.uid);
        final driverSnapshot = await driverRef.get();

        if (driverSnapshot.exists) {

          driverName = driverSnapshot.child('userName').value as String? ?? 'Unknown Driver';

        }
      } catch (e) {

        logger.e("Error fetching driver's name: $e");

      }

      final ride = RideModel(
        rideId: rideId,
        driverId: _currentUser!.uid,
        driverName: driverName, // Fetch driverName from Firestore
        passengerIds: [],
        origin: _originController.text,
        destination: _destinationController.text,
        journeyDate: _selectedDate!,
        journeyTime: _selectedTime!.format(context),
        price: finalPrice,
        seatsAvailable: passengers,
        distance: const Distance().as(
          LengthUnit.Kilometer,
          _originLatLng!,
          _destinationLatLng!,
        ),
        originLat: _originLatLng!.latitude,
        originLng: _originLatLng!.longitude,
        destinationLat: _destinationLatLng!.latitude,
        destinationLng: _destinationLatLng!.longitude,
      );

      final commonMethods = CommonMethods();
      await commonMethods.checkConnectivity(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const LoadingDialouge(messageText: "Creating Ride...");
        },
      );

      try {

        logger.i("Attempting to create ride...");
        final rideService = RideService();
          await rideService.createRide(
            ride,
            _originLatLng!.latitude,
            _originLatLng!.longitude,
            _destinationLatLng!.latitude,
            _destinationLatLng!.longitude,
          );
        logger.i("Ride created successfully!");

      } catch (e) {
        
        logger.e("Error creating ride: $e");
        if (context.mounted) Navigator.of(context).pop(); // Close the loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Failed to create ride: ${e.toString()}')),

        );
        return;
      }

      // Log success, including the final price
      logger.i("Ride created successfully from $_originLatLng to $_destinationLatLng at price \$${finalPrice.toStringAsFixed(2)}");

      if (context.mounted) Navigator.of(context).pop(true); // Pass `true` to indicate success

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Ride created successfully!')),

      );

      Navigator.of(context).pop();

      if (context.mounted) {

        Navigator.of(context).pushReplacementNamed('/homescreen');
        
      }

    } finally {
      setState(() {
        _isCreatingRide = false; // Reset loading state
      });
    }

  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Ride"),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.tealAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // Rounded corners
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color.fromARGB(255, 217, 238, 237), Color.fromARGB(255, 118, 190, 184)], // Subtle gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20), // Match the rounded corners
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Ride Details",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const Divider(
                            thickness: 1.5,
                            color: Colors.teal,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _originController,
                            decoration: InputDecoration(
                              labelText: "Origin",
                              prefixIcon: const Icon(Icons.location_on, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.5), // Semi-transparent fill
                            ),
                            onChanged: (val) {
                              if (val.length > 2) {
                                _fetchMapboxSuggestions(val, true);
                              }
                            },
                          ),
                          ..._originSuggestions.map((s) => ListTile(
                                title: Text(s['place_name']),
                                onTap: () => _onSuggestionTap(s, true),
                              )),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _destinationController,
                            decoration: InputDecoration(
                              labelText: "Destination",
                              prefixIcon: const Icon(Icons.flag, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.5), // Semi-transparent fill
                            ),
                            onChanged: (val) {
                              if (val.length > 2) {
                                _fetchMapboxSuggestions(val, false);
                              }
                            },
                          ),
                          ..._destinationSuggestions.map((s) => ListTile(
                                title: Text(s['place_name']),
                                onTap: () => _onSuggestionTap(s, false),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white.withOpacity(0.8), // Glassmorphism effect
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Schedule",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const Divider(
                            thickness: 1.5,
                            color: Colors.teal,
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _selectDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.teal, Colors.tealAccent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.teal.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.calendar_today, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          _selectedDate == null
                                              ? "Select Date"
                                              : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _selectTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.teal, Colors.tealAccent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.teal.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.access_time, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          _selectedTime == null
                                              ? "Select Time"
                                              : "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_selectedDate != null || _selectedTime != null)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.teal, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_selectedDate != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: Colors.teal),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (_selectedTime != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time, color: Colors.teal),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Time: ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // Rounded corners
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.teal, Colors.tealAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20), // Match the rounded corners
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Passenger & Price",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Divider(
                            thickness: 1.5,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 15),
                          // Top Row: Passengers and Estimated Price
                          Row(
                            children: [
                              // Number of Passengers Field
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  child: TextFormField(
                                    controller: _passengerController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: "Passengers",
                                      prefixIcon: const Icon(Icons.person, color: Colors.white),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.2),
                                      labelStyle: const TextStyle(color: Colors.white),
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10.0,
                                        horizontal: 12.0,
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              // Estimated Price Field
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  child: TextFormField(
                                    controller: _priceController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: "Est. Price",
                                      prefixIcon: const Icon(Icons.attach_money, color: Colors.white),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.2),
                                      labelStyle: const TextStyle(color: Colors.white),
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10.0,
                                        horizontal: 12.0,
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Bottom Row: Driver's Price Field
                          Center(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.6, // Centered and smaller width
                              child: TextFormField(
                                controller: _driverPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Driver's Price",
                                  prefixIcon: const Icon(Icons.money, color: Colors.white),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  labelStyle: const TextStyle(color: Colors.white),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                    horizontal: 12.0,
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.teal, Color.fromARGB(255, 53, 182, 152)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _createRide,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), // Rounded corners
                          ),
                          elevation: 0,
                          backgroundColor: Colors.transparent, // Transparent to allow gradient
                          shadowColor: Colors.transparent,
                        ),
                        child: const Text(
                          "Create Ride",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Updated text color
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

Future<void> createRide(RideModel ride, double originLat, double originLng, double destinationLat, double destinationLng) async {
  try {

    // Calculate distance
    final distance = const Distance().as(
      LengthUnit.Kilometer,
      LatLng(originLat, originLng),
      LatLng(destinationLat, destinationLng),
    );

    // Fetch driver's name from Firestore
    final driverDoc = await FirebaseFirestore.instance.collection('users').doc(ride.driverId).get();
    final driverName = driverDoc.data()?['userName'] ?? 'Unknown Driver';


    // Creating a new RideModel with the calculated distance
    final rideWithDistance = RideModel(
      rideId: ride.rideId,
      driverId: ride.driverId,
      driverName: driverName, // Add the required driverName parameter
      passengerIds: ride.passengerIds,
      origin: ride.origin,
      destination: ride.destination,
      journeyDate: ride.journeyDate,
      journeyTime: ride.journeyTime,
      price: ride.price,
      seatsAvailable: ride.seatsAvailable,
      distance: distance, // Add distance
      originLat: originLat,
      originLng: originLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    );
   
    print("Ride Data: ${ride.toMap()}");

    await _firestore.collection('rides').doc(ride.rideId).set(rideWithDistance.toMap());

    print("Ride successfully written to Firestore.");
  } catch (e) {

    print("Error writing ride to Firestore: $e");
    throw Exception('Failed to create ride: $e');

  }
}
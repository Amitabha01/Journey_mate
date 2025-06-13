import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
//import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
//import 'package:geolocator/geolocator.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../../methods/common_connection_methods.dart';
import '../../widgets/loading_dialouge.dart';
import 'package:firebase_database/firebase_database.dart';
//import 'package:logger/logger.dart';

final String mapboxApiKey = dotenv.env["MAPBOX_ACCESS_TOKEN_KEY"] ?? "";
//final Logger logger = Logger();

class SearchRidePage extends StatefulWidget {
  @override
  _SearchRidePageState createState() => _SearchRidePageState();
}

class _SearchRidePageState extends State<SearchRidePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Ride"),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.tealAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAutocompleteField("Origin", "Enter origin", _originController, true),
                        const SizedBox(height: 16),
                        _buildAutocompleteField("Destination", "Enter destination", _destinationController, false),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildDateField(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _buildTextField(
                                "Passengers",
                                "Enter number",
                                _passengersController,
                                Icons.person,
                                isNumeric: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSearchButton(),
                      ],
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildAvailableRidesSection(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _passengersController = TextEditingController();
  DateTime? _selectedDate;
  List<RideModel> _availableRides = [];
  bool _isLoading = false;
  // ignore: unused_field
  LatLng? _originLatLng;
  // ignore: unused_field
  LatLng? _destinationLatLng;

  final RideService _rideService = RideService();
  final CommonMethods _commonMethods = CommonMethods();

  // Suggestions for origin and destination
  List<dynamic> _originSuggestions = [];
  List<dynamic> _destinationSuggestions = [];

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _passengersController.dispose();
    super.dispose();
  }

  Future<void> _fetchMapboxSuggestions(String input, bool isOrigin) async {
    if (input.isEmpty) {
      setState(() {
        if (isOrigin) {
          _originSuggestions = [];
        } else {
          _destinationSuggestions = [];
        }
      });
      return;
    }

    final String apiUrl =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$input.json?access_token=$mapboxApiKey&autocomplete=true&limit=5';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> features = data['features'];

        setState(() {
          if (isOrigin) {
            _originSuggestions = features;
          } else {
            _destinationSuggestions = features;
          }
        });
      } else {
        print('Failed to fetch suggestions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching location suggestions: $e');
    }
  }

  void _onSuggestionTap(Map<String, dynamic> suggestion, bool isOrigin) {
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
    });
  }

  Widget _buildAutocompleteField(String label, String hint, TextEditingController controller, bool isOrigin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.location_on, color: Colors.teal),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            _fetchMapboxSuggestions(value, isOrigin);
          },
        ),
        const SizedBox(height: 8),
        if ((isOrigin ? _originSuggestions : _destinationSuggestions).isNotEmpty)
          Container(
            height: 200,
            child: ListView.builder(
              itemCount: (isOrigin ? _originSuggestions : _destinationSuggestions).length,
              itemBuilder: (context, index) {
                final suggestion = (isOrigin ? _originSuggestions : _destinationSuggestions)[index];
                return ListTile(
                  title: Text(suggestion['place_name']),
                  onTap: () {
                    _onSuggestionTap(suggestion, isOrigin);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Date",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: _selectedDate == null
                ? "Select date..."
                : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
            prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          onTap: _selectDate,
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, IconData icon, {bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.teal),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _searchRides,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "Search",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableRidesSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Available Rides",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _availableRides.isEmpty
                    ? const Center(
                        child: Text(
                          "No rides found.",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _availableRides.length,
                        itemBuilder: (context, index) {
                          final ride = _availableRides[index];
                          return _buildRideCard(ride);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: const Icon(Icons.directions_car, color: Colors.white),
        ),
        title: Text("${ride.origin} → ${ride.destination}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Driver: ${ride.driverName}"), // Display driver's name
            Text("Date: ${ride.journeyDate.toLocal().toString().split(' ')[0]}"), // Display date
            Text("Seats Available: ${ride.seatsAvailable}"),
            Text("Price: \$${ride.price.toStringAsFixed(2)}"), // Display price
            Text("Distance: ${ride.distance.toStringAsFixed(1)} km"), // Display distance
          ],
        ),
        onTap: () {
          try {
            Navigator.pushNamed(
              context,
              '/confirmBooking',
              arguments: {'ride': ride}, // Pass the selected ride details
            );
          } catch (e) {
            print("Error navigating to Confirm Booking: $e");
          }
        },
      ),
    );
  }

  Future<void> _searchRides() async {
    if (_originController.text.isEmpty ||
        _destinationController.text.isEmpty ||
        _selectedDate == null ||
        _passengersController.text.isEmpty ||
        int.tryParse(_passengersController.text) == null ||
        int.parse(_passengersController.text) < 1) {
      _commonMethods.displaySnackBar(context, 'Please fill all fields correctly.');
      return;
    }

    await _commonMethods.checkConnectivity(context);

    // Show the loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialouge(messageText: "Searching for rides..."),
    );

    // Simulate a delay of 1 second
    await Future.delayed(const Duration(seconds: 1));

    try {
      final ridesStream = _rideService.getAvailableRides();
      final rides = await ridesStream.first;
      final filteredRides = _filterRides(rides);

      setState(() {
        _availableRides = filteredRides;
      });
    } catch (e) {
      _commonMethods.displaySnackBar(context, 'Error fetching rides: $e');
    } finally {
      // Close the loading dialog after 1 second
      if (context.mounted) Navigator.pop(context);
    }
  }

  List<RideModel> _filterRides(List<RideModel> rides) {
    return rides.where((ride) {
      final matchesOrigin = _originController.text.isEmpty ||
          ride.origin.toLowerCase().contains(_originController.text.toLowerCase());
      final matchesDestination = _destinationController.text.isEmpty ||
          ride.destination.toLowerCase().contains(_destinationController.text.toLowerCase());
      final matchesDate = _selectedDate == null ||
          ride.journeyDate.toLocal().toString().split(' ')[0] ==
              _selectedDate!.toLocal().toString().split(' ')[0];
      final matchesPassengers = _passengersController.text.isEmpty ||
          ride.seatsAvailable >= (int.tryParse(_passengersController.text) ?? 0).toInt();

      return matchesOrigin && matchesDestination && matchesDate && matchesPassengers;
    }).toList();
  }

  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<List<RideModel>> fetchRidesWithDriverNames() async {
    final ridesSnapshot = await FirebaseFirestore.instance.collection('rides').get();

    final rides = await Future.wait(ridesSnapshot.docs.map((doc) async {

      final ride = await RideModel.fromFirestore(doc);

      // Use the driverName from Firestore if it exists and is valid
      if (ride.driverName.isNotEmpty && ride.driverName != 'Unknown Driver') {
        return ride;
      }
      
      // Otherwise, fetch the driverName from Realtime Database
      ride.driverName = await fetchDriverName(ride.driverId);
      return ride;

    }).toList());

    return rides.cast<RideModel>();
  }

  Future<String> fetchDriverName(String driverId) async {
    try {
      //logger.i("Fetching driver name for driverId: $driverId"); // Info log
      final DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(driverId);
      final DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        final driverName = snapshot.child('userName').value as String? ?? 'Unknown Driver';
        //logger.i("Driver name fetched: $driverName"); // Info log
        return driverName;
      } else {
        //logger.w("Driver document does not exist for driverId: $driverId"); // Warning log
        return 'Unknown Driver1';
      }
    } catch (e) {
      print("Error fetching driver name: $e"); // Error log
      return 'Unknown Driver2';
    }
  }
}

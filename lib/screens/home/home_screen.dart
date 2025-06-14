import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
// ignore: unused_import
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:journey_mate_app_v1/methods/common_connection_methods.dart';
//import 'package:journey_mate_app_v1/screens/rides/create_ride_screen.dart' as create_ride;
//import 'package:journey_mate_app_v1/widgets/loading_dialouge.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
// ignore: unused_import
import 'package:mapbox_search/mapbox_search.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/ride_service.dart';
import '../../models/ride_model.dart';
//import '../rides/your_rides_screen.dart' as rides_screen;
import '../rides/search_ride_screen.dart';


final String mapboxApiKey = dotenv.env["MAPBOX_ACCESS_TOKEN_KEY"] ?? "";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  mp.MapboxMap? mapboxMapController;
  RideModel? _selectedRide; // Track the currently selected ride

  StreamSubscription? userPositionStream;

  final RideService _rideService = RideService();
  late Stream<List<RideModel>> rideStream;

  List<RideModel> _rides = [];

  @override
  void dispose() {
    userPositionStream?.cancel();
    super.dispose();
    mapboxMapController?.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Check if the user is logged in
    _checkUserLoggedIn();

    print("HomeScreen initialized");

    _setupPositionTraking(); // Requesting location permission
    _fetchRides(); // Fetch rides when the home screen is initialized

    rideStream = RideService().getAvailableRides(); // Initialize the ride stream
  }

  Future<void> _checkUserLoggedIn() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // If the user is not logged in, redirect to the SignInPage
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
      }
    }
  }

  Future<void> _fetchRides() async {
    final commonMethods = CommonMethods();

    // Check internet connectivity
    await commonMethods.checkConnectivity(context);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('No user is logged in.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final userId = currentUser.uid;
    final now = DateTime.now();

    try {
      // Fetch active confirmed rides for the current user
      final confirmedRidesSnapshot = await FirebaseFirestore.instance
          .collection('confirmedRides')
          .where('passengerId', isEqualTo: userId)
          .get();

      final confirmedRides = confirmedRidesSnapshot.docs.map((doc) => RideModel.fromMap(doc.data())).toList();

      // Filter out expired confirmed rides
      final activeConfirmedRides = confirmedRides.where((ride) {
        final rideDateTime = DateTime.parse('${ride.journeyDate} ${ride.journeyTime}');
        return rideDateTime.isAfter(now); // Only include future rides
      }).toList();

      if (activeConfirmedRides.isNotEmpty) {
        // If there are active confirmed rides, show only these
        activeConfirmedRides.sort((a, b) {
          final aDateTime = DateTime.parse('${a.journeyDate} ${a.journeyTime}');
          final bDateTime = DateTime.parse('${b.journeyDate} ${b.journeyTime}');
          return aDateTime.compareTo(bDateTime); // Sort by closest date and time
        });

        setState(() {
          _rides = activeConfirmedRides;
        });

        debugPrint('Showing active confirmed rides: ${_rides.length}');
        return;
      }

      // If no active confirmed rides, fetch all active rides
      _rideService.getAvailableRides().listen((rides) {
        // Filter out expired rides
        final nonExpiredRides = rides.where((ride) {
          final rideDateTime = DateTime.parse('${ride.journeyDate} ${ride.journeyTime}');
          return rideDateTime.isAfter(now);
        }).toList();

        setState(() {
          _rides = nonExpiredRides;
        });

        debugPrint('Showing all active rides: ${_rides.length}');
      });
    } catch (e) {
      debugPrint('Error fetching rides: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch rides')),
      );
    }
  }


  Future<void> _fetchUserRidesAndNavigate(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('No user is logged in.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final userId = currentUser.uid;

    try {
      // Fetch all available rides
      final rides = await RideService().getAvailableRides().first;

      // Filter rides where the user is the driver or a passenger
      final userRides = rides.where((ride) {
        final isDriver = ride.driverId == userId;
        final isPassenger = ride.passengerIds.contains(userId);
        debugPrint('Ride: ${ride.rideId}, isDriver: $isDriver, isPassenger: $isPassenger');
        return isDriver || isPassenger;
      }).toList();

      debugPrint('Filtered user rides: ${userRides.length}');

      if (userRides.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No rides found for the current user')),
        );
        return;
      }

      if (context.mounted) {
        Navigator.pushNamed(context, '/yourrides');
      }
    } catch (e) {
      debugPrint('Error fetching user rides: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch your rides')),
      );
    }
  }

  Future<void> _setupPositionTraking() async {
    bool servicesEnabled = await gl.Geolocator.isLocationServiceEnabled();

    if (!servicesEnabled) {
      print("No No location not avalable. Please enable them.");

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Location Service Disabled"),
            content: const Text(
                "Location services are disabled. Please enable them in settings."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  gl.Geolocator.openLocationSettings();
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        );
      }

      return;
    }

    gl.LocationPermission permission = await gl.Geolocator.checkPermission();

    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();

      if (permission == gl.LocationPermission.denied) {
        print("Location permission denied");

        return;
      }
    }

    if (permission == gl.LocationPermission.deniedForever) {
      print("Location permission permanently denied.");

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Permission Required"),
            content: const Text(
                "Location permission is permanently denied. Please enable it in app settings."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        );
      }

      return;
    }

    gl.LocationSettings locationSettings = gl.LocationSettings(
      accuracy: gl.LocationAccuracy.high,
      distanceFilter: 100,
    );

    userPositionStream?.cancel();

    userPositionStream = gl.Geolocator.getPositionStream(
        locationSettings: locationSettings).listen(
      (gl.Position? position) {
        if (position != null && mapboxMapController != null) {
          mapboxMapController?.setCamera(
            mp.CameraOptions(
              zoom: 13,
              center: mp.Point(
                coordinates: mp.Position(position.longitude, position.latitude),
              ),
            ),
          );

          CommonMethods().displaySnackBar(context, position.toString());
        }
      },
    );

    // If permissions are granted, you can now access the user's location
    gl.Position position = await gl.Geolocator.getCurrentPosition();
    print("User's location: ${position.latitude}, ${position.longitude}");
  }

  Future<Uint8List> loadHQRedMarkerImage() async {
    var byteData = await rootBundle.load("assets/images/1000521835.png");

    return byteData.buffer.asUint8List();
  }

  void _onMapCreated(mp.MapboxMap controller) async {
    setState(() {
      mapboxMapController = controller;
    });

    // Check if permissions were granted (just in case)
    gl.LocationPermission permission = await gl.Geolocator.checkPermission();

    // Logic for displaying the user's location

    if (permission == gl.LocationPermission.whileInUse ||
        permission == gl.LocationPermission.always) {
      await mapboxMapController?.location.updateSettings(
        mp.LocationComponentSettings(
          enabled: true,
          showAccuracyRing: true,
          pulsingEnabled: true,
        ),
      );
    } else {
      print("Location permission not granted");
    }

    // Remove hardcoded marker logic
    // Markers and routes will now be dynamically added using `_showRouteOnMap`
  }

  Future<void> _showRouteOnMap(mp.Position origin, mp.Position destination, {bool clearOnly = false}) async {
    if (mapboxMapController == null) {
      debugPrint('MapboxMapController is not initialized');
      return;
    }

    // Clear existing annotations (markers and polylines)
    final annotationManager = await mapboxMapController?.annotations.createPointAnnotationManager();
    if (annotationManager != null) {
      await annotationManager.deleteAll();
    }

    if (clearOnly) {
      return; // If only clearing is requested, exit here
    }

    // Add markers for origin and destination
    final pointAnnotationManager = await mapboxMapController?.annotations.createPointAnnotationManager();

    // Add origin marker
    final originMarker = mp.PointAnnotationOptions(
      geometry: mp.Point(coordinates: origin),
      iconSize: 0.1,
      image: await loadHQRedMarkerImage(),
    );
    pointAnnotationManager?.create(originMarker);
                                                                                                                                               
    // Add destination marker
    final destinationMarker = mp.PointAnnotationOptions(
      geometry: mp.Point(coordinates: destination),
      iconSize: 0.1,
      image: await loadHQRedMarkerImage(),
    );
    pointAnnotationManager?.create(destinationMarker);

    // Fetch and draw the route
    final routeData = await _fetchRoute(origin, destination);
    if (routeData != null) {
      final coordinates = routeData['coordinates'] as List<mp.Position>;

      // Draw the route on the map
      final lineAnnotationManager = await mapboxMapController?.annotations.createPolylineAnnotationManager();
      final lineOptions = mp.PolylineAnnotationOptions(
        geometry: mp.LineString(coordinates: coordinates),
        lineColor: Colors.blue.value,
        lineWidth: 5.0,
      );
      lineAnnotationManager?.create(lineOptions);

      // Automatically adjust the camera to fit the route
      final cameraOptions = await mapboxMapController?.cameraForCoordinates(
        coordinates.map((pos) => mp.Point(coordinates: pos)).toList(),
        mp.MbxEdgeInsets(
          top: 50.0,
          bottom: 50.0,
          left: 50.0,
          right: 50.0,
        ),
        0.0, // Default bearing
        0.0  // Default pitch
      );

      if (cameraOptions != null) {
        mapboxMapController?.flyTo(
          cameraOptions,
          mp.MapAnimationOptions(duration: 1000),
        );
      }
    }
  }

  // Helper method to calculate zoom level based on distance
  // double _calculateZoomLevel(double distance) {
  //   if (distance < 1000) {
  //     return 14.0; // Close range
  //   } else if (distance < 5000) {
  //     return 12.0; // Medium range
  //   } else if (distance < 10000) {
  //     return 10.0; // Long range
  //   } else {
  //     return 8.0; // Very long range
  //   }
  // }

  // Dummy implementation of _fetchRoute. Replace with actual API call if needed.
  Future<Map<String, dynamic>?> _fetchRoute(mp.Position origin, mp.Position destination) async {
    debugPrint('Fetching route: Origin = (${origin.lng}, ${origin.lat}), Destination = (${destination.lng}, ${destination.lat})');
    final url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${origin.lng},${origin.lat};${destination.lng},${destination.lat}?geometries=geojson&access_token=$mapboxApiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] == null || data['routes'].isEmpty) {
          debugPrint('No routes found in the API response');
          return null;
        }

        final route = data['routes'][0];
        final coordinates = route ['geometry']['coordinates'] as List;

        // Convert coordinates to List<mp.Position>
        final parsedCoordinates = coordinates.map<mp.Position>((coord) {
          return mp.Position(coord[0] as double, coord[1] as double);
        }).toList();

        final distance = route['distance'] / 1000; // Convert to kilometers
        final duration = route['duration'] / 60; // Convert to minutes

        logger.i('Route fetched successfully: Distance = $distance km, Duration = $duration mins');

        return {
          //'coordinates': coordinates.map((coord) => mp.Position(coord[0], coord[1])).toList(),
          'coordinates': parsedCoordinates,
          'distance': distance,
          'duration': duration,
        };

      } else {
        throw Exception('Failed to fetch route');
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
      return null;
    }
  }

  // Removed unused '_onRideSelected' method to resolve the compile error.

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, mp.Position>?;

    if (args != null) {
      final origin = args['origin']!;
      final destination = args['destination']!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRouteOnMap(origin, destination);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Mapbox Map
          mp.MapWidget(
            onMapCreated: (controller) {
              print("MapWidget created successfully");
              _onMapCreated(controller);
            },
            styleUri: mp.MapboxStyles.MAPBOX_STREETS,
          ),
          // Overlay UI
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome to Journey Mate",
                  style: TextStyle(
                    fontSize: 24,
                    color: const ui.Color.fromARGB(255, 187, 90, 90),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchRidePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 10,
                    shadowColor: Colors.teal.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Search",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Ride List
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: StreamBuilder<List<RideModel>>(
                stream: rideStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No active rides found."));
                  }

                  final rides = snapshot.data!;

                  return ListView.builder(
                    itemCount: rides.length,
                    itemBuilder: (context, index) {
                      final ride = rides[index];
                      final isConfirmed = ride.label == "Confirmed"; // Check if the ride is confirmed

                      return Card(
                        color: isConfirmed ? Colors.teal.withOpacity(0.1) : Colors.white, // Highlight confirmed rides
                        elevation: isConfirmed ? 5 : 2, // Add elevation for confirmed rides
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: isConfirmed
                              ? const BorderSide(color: Colors.teal, width: 2) // Add border for confirmed rides
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          leading: isConfirmed
                              ? const Icon(Icons.check_circle, color: Colors.teal, size: 30) // Add icon for confirmed rides
                              : const Icon(Icons.directions_car, color: Colors.grey, size: 30),
                          title: Text(
                            '${ride.origin} ➝ ${ride.destination}',
                            style: TextStyle(
                              fontWeight: isConfirmed ? FontWeight.bold : FontWeight.normal,
                              color: isConfirmed ? Colors.teal : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ride.journeyDate.toLocal().toString().split(" ")[0]} at ${ride.journeyTime} | ₹${ride.price}',
                              ),
                              if (isConfirmed)
                                const Text(
                                  "Confirmed",
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text('${ride.seatsAvailable} seats'),
                          onTap: () {
                            logger.i('Ride tapped: ${ride.toMap()}');
                            logger.i('Current selected ride: ${_selectedRide?.toMap()}');

                            if (ride.originLat != 0.0 &&
                                ride.originLng != 0.0 &&
                                ride.destinationLat != 0.0 &&
                                ride.destinationLng != 0.0) {
                              if (_selectedRide == ride) {
                                // If the same ride is tapped again, clear the map
                                logger.i('Clearing route for ride: ${ride.toMap()}');
                                _showRouteOnMap(
                                  mp.Position(ride.originLng, ride.originLat),
                                  mp.Position(ride.destinationLng, ride.destinationLat),
                                  clearOnly: true,
                                );
                                setState(() {
                                  _selectedRide = null; // Deselect the ride
                                });
                              } else {
                                // Show the route for the selected ride
                                logger.i('Showing route for ride: ${ride.toMap()}');
                                _showRouteOnMap(
                                  mp.Position(ride.originLng, ride.originLat),
                                  mp.Position(ride.destinationLng, ride.destinationLat),
                                );
                                setState(() {
                                  _selectedRide = ride; // Update the selected ride
                                });
                              }
                            } else {
                              logger.e('Invalid coordinates for the selected ride.');
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Update this dynamically based on the selected tab
        onTap: (index) async {
          switch (index) {
            case 0:
              // Navigate to Search Screen
              Navigator.pushNamed(context, '/search');
              break;
            case 1:
              // Navigate to Create Ride Screen
              final result = await Navigator.pushNamed(context, '/createride');
              if (result == true) {
                // Refresh the ride stream after creating a ride
                setState(() {
                  rideStream = RideService().getAvailableRides();
                });
              }
              break;
            case 2:
              // Navigate to Your Rides Screen
              await _fetchUserRidesAndNavigate(context);
              break;
            case 3:
              // Navigate to Inbox Screen
              Navigator.pushNamed(context, '/inbox');
              break;
            case 4:
              // Navigate to Profile Screen
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Publish',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Your Rides',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}


final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Stream<List<RideModel>> getAvailableRides() async* {
  try {
    final ridesSnapshot = await _firestore.collection('rides').get();

    //emni
    for (var doc in ridesSnapshot.docs) {
      debugPrint('Ride document: ${doc.data()}');
    }

    final rides = await Future.wait(ridesSnapshot.docs.map((doc) async {
      try {
        final rideData = doc.data();
        String driverName = rideData['driverName'] ?? 'Unknown Driver';

        // Fetch driver name from Realtime Database if missing
        if (driverName == 'Unknown Driver') {
          final driverId = rideData['driverId'];
          try {
            final driverRef = FirebaseDatabase.instance.ref().child('users').child(driverId);
            final driverSnapshot = await driverRef.get();
            if (driverSnapshot.exists) {
              driverName = driverSnapshot.child('userName').value as String? ?? 'Unknown Driver';
            }
          } catch (e) {
            debugPrint("Error fetching driver name from Realtime Database: $e");
          }
        }

      } catch (e) {
        debugPrint('Error parsing ride document: $e');
        return null; // Skip invalid rides
      }
    }).toList());

    yield rides.whereType<RideModel>().toList(); // Filter out null rides
  } catch (e) {
    debugPrint('Error fetching available rides: $e');
    yield [];
  }
}

class DriverHomeScreen extends StatelessWidget {
  final String driverId;

  const DriverHomeScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Home"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookingRequests')
            .where('driverId', isEqualTo: driverId)
            .where('status', isEqualTo: 'pending') // Only show pending requests
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No booking requests."));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                child: ListTile(
                  title: Text("From: ${request['origin']} ➝ To: ${request['destination']}"),
                  subtitle: Text(
                    "Date: ${request['journeyDate'].toDate().toString().split(' ')[0]} | Price: ₹${request['price']}",
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showDriverPopup(context, request);
                    },
                    child: const Text("Respond"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDriverPopup(BuildContext context, QueryDocumentSnapshot request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Booking Request"),
          content: Text(
              "${request['passengerId']} is requesting a ride. Would you like to accept or reject?"),
          actions: [
            TextButton(
              onPressed: () async {
                await _updateRequestStatus(request.id, 'accepted');
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Booking request accepted.")),
                );
              },
              child: const Text("Accept"),
            ),
            TextButton(
              onPressed: () async {
                await _updateRequestStatus(request.id, 'rejected');
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Booking request rejected.")),
                );
              },
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    await FirebaseFirestore.instance.collection('bookingRequests').doc(requestId).update({
      'status': status,
    });
  }
}

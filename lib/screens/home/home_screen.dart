import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:journey_mate_app_v1/methods/common_connection_methods.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'package:permission_handler/permission_handler.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  mp.MapboxMap? mapboxMapController;

  StreamSubscription? userPositionStream;

  @override
  void dispose() {
    userPositionStream?.cancel();
    super.dispose();
    mapboxMapController?.dispose();
  }


  @override
  void initState() {
    
    super.initState();
    print("HomeScreen initialized");

    _setupPositionTraking();  //requesting location permission
   
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
              content: const Text("Location services are disabled. Please enable them in settings."),
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
      print("Location permission permanently denied. Please enable it in settings.");

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Permission Required"),
              content: const Text("Location permission is permanently denied. Please enable it in app settings."),
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

      userPositionStream = gl.Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (gl.Position? position) {

          if (position != null) {
            CommonMethods().displaySnackBar(context, position.toString());
          }
        },
      );


    // If permissions are granted, you can now access the user's location
    gl.Position position = await gl.Geolocator.getCurrentPosition();
    print("User's location: ${position.latitude}, ${position.longitude}");

  }


  void _onMapCreated(mp.MapboxMap controller) async{

    setState(() {

      mapboxMapController = controller;
      
    });

    // Check if permissions were granted (just in case)
    gl.LocationPermission permission = await gl.Geolocator.checkPermission();
    
    if (permission == gl.LocationPermission.whileInUse ||
        permission == gl.LocationPermission.always ) {
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
    
  }


  @override
  Widget build(BuildContext context) {

    return  Scaffold(
      
      body: Stack(

        children: [

          //map

          mp.MapWidget(

            onMapCreated: _onMapCreated

          ),
          
            //searchbar

          //  Positioned(
          //     top: 20,
          //   left: 20,
          //   right: 20,
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 16),
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(8),
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.black.withOpacity(0.1),
          //           blurRadius: 10,
          //           offset: const Offset(0, 5),
          //         ),
          //       ],
          //     ),
          //     child: Row(
          //       children: [
          //         const Icon(Icons.search, color: Colors.grey),
          //         const SizedBox(width: 10),
          //         Expanded(
          //           child: TextField(
          //             decoration: const InputDecoration(
          //               hintText: 'Search for a ride...',
          //               border: InputBorder.none,
          //             ),
          //             onChanged: (value) {
          //               // Handle search input
          //             },
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

            // Ride Options

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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    leading: const Icon(Icons.directions_car, color: Colors.blue),
                    title: const Text('Ride to City Center'),
                    subtitle: const Text('Driver: John Doe'),
                    trailing: const Text('\$10'),
                    onTap: () {
                      // Handle ride selection
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.directions_car, color: Colors.green),
                    title: const Text('Ride to Airport'),
                    subtitle: const Text('Driver: Jane Smith'),
                    trailing: const Text('\$20'),
                    onTap: () {
                      // Handle ride selection
                    },
                  ),
                  // Add more ride options here
                ],
              ),
            ),
          ),

        ],

      )
      
    );
    
  }
}
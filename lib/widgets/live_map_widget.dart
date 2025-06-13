import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;

class LiveMapWidget extends StatelessWidget {
  final List<Map<String, double>> userLocations;
  const LiveMapWidget({super.key, required this.userLocations});

  @override
  Widget build(BuildContext context) {
    // Render map and markers for each user location
    return mp.MapWidget(
      // Add logic to show markers for each user location
    );
  }
}
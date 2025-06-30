import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatelessWidget {
  final double lat;
  final double lng;

  const MapScreen({super.key, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final LatLng location = LatLng(lat, lng);
    return Scaffold(
      appBar: AppBar(title: const Text("Lokasi Absen")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: location,
          zoom: 17,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('absen'),
            position: location,
            infoWindow: const InfoWindow(title: 'Lokasi Absen'),
          ),
        },
      ),
    );
  }
}

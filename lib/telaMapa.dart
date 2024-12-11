import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MusicMapScreen extends StatefulWidget {
  final LatLng currentLocation;
  final List<Map<String, dynamic>> musicLocations;

  const MusicMapScreen({
    Key? key,
    required this.currentLocation,
    required this.musicLocations,
  }) : super(key: key);

  @override
  State<MusicMapScreen> createState() => _MusicMapScreenState();
}

class _MusicMapScreenState extends State<MusicMapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _addInitialMarkers();
  }

  void _addInitialMarkers() {
    // Adiciona marcador da localização atual
    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: widget.currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Você está aqui'),
      ),
    );

    // Adiciona marcadores para as localizações musicais
    for (var music in widget.musicLocations) {
      if (music['location'] != null && music['location'] is LatLng) {
        final LatLng location = music['location'];
        _markers.add(
          Marker(
            markerId: MarkerId(location.toString()),
            position: location,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(title: music['name'] ?? 'Sem nome'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Músicas Próximas'),
        centerTitle: true,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.currentLocation,
          zoom: 15.0,
        ),
        markers: _markers, // Adiciona os marcadores ao mapa
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

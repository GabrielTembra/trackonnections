import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MusicMapScreen(),
    );
  }
}

class MusicMapScreen extends StatefulWidget {
  const MusicMapScreen({Key? key}) : super(key: key);

  @override
  State<MusicMapScreen> createState() => _MusicMapScreenState();
}

class _MusicMapScreenState extends State<MusicMapScreen> {
  late GoogleMapController mapController;
  LatLng _currentLocation = const LatLng(-23.550520, -46.633308); // Coordenadas iniciais (São Paulo)
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  /// Inicializa o mapa e atualiza a localização atual com marcador.
  Future<void> _initializeLocation() async {
    final Location location = Location();

    // Verifique se a permissão foi concedida
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return; // Caso o serviço de localização não esteja ativado
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return; // Caso a permissão não tenha sido concedida
      }
    }

    // Agora obtenha a localização atual
    LocationData currentLocation = await location.getLocation();

    // Atualizando o marcador e o mapa com a nova localização
    setState(() {
      _currentLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      _markers.clear(); // Limpa os marcadores antigos antes de adicionar o novo
      _markers.add(
        Marker(
          markerId: const MarkerId('trackonnections'),
          position: _currentLocation,
          infoWindow: const InfoWindow(title: 'Trackonnections'),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });

    // Centraliza o mapa na localização atual
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 15,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: Set<Marker>.of(_markers),
        myLocationEnabled: true, // Mostra o ponto azul da localização atual
        myLocationButtonEnabled: true, // Habilita o botão para focar na localização
      ),
    );
  }
}

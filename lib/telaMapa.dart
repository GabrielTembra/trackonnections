import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart'; // Para integrar com o ProfileProvider
import 'profile_provider.dart'; // Importe seu ProfileProvider

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ProfileProvider(),
      child: const MyApp(),
    ),
  );
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
    // Atualize a localização ao inicializar
    _initializeLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Chama a atualização da localização sempre que a tela for reconstruída
    _initializeLocation();
  }

  /// Inicializa o mapa e atualiza a localização atual com marcador.
  Future<void> _initializeLocation() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    // Verifique se a localização foi carregada do provedor
    if (profileProvider.latitude != 0.0 && profileProvider.longitude != 0.0) {
      setState(() {
        _currentLocation = LatLng(profileProvider.latitude, profileProvider.longitude);
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
    } else {
      // Caso não tenha localização, use a função para obter a localização atual do dispositivo
      await _getDeviceLocation();
    }
  }

  /// Função para obter a localização do dispositivo
  Future<void> _getDeviceLocation() async {
    final Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return; // Serviço de localização desativado
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return; // Permissão negada
      }
    }

    LocationData currentLocation = await location.getLocation();

    // Atualiza a localização no ProfileProvider
    Provider.of<ProfileProvider>(context, listen: false).saveProfileData(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
    );

    // Atualiza a localização do mapa
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

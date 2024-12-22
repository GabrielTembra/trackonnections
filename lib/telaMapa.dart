import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart'; // Importando o pacote location para a geolocalização
import 'package:provider/provider.dart';
import 'profile_provider.dart'; // Importe o ProfileProvider

class MusicMapScreen extends StatefulWidget {
  const MusicMapScreen({Key? key}) : super(key: key);

  @override
  State<MusicMapScreen> createState() => _MusicMapScreenState();
}

class _MusicMapScreenState extends State<MusicMapScreen> with AutomaticKeepAliveClientMixin {
  late GoogleMapController mapController;
  LatLng _currentLocation = const LatLng(-23.550520, -46.633308); // Coordenadas iniciais (São Paulo)
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _getLocationFromBrowser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeLocation();
  }

  // Função para inicializar a localização
  Future<void> _initializeLocation() async {
    await _getDeviceLocation();
  }

  // Função para obter a localização do dispositivo
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

    setState(() {
      _currentLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('trackonnections'),
          position: _currentLocation,
          infoWindow: const InfoWindow(title: 'Trackonnections'),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });

    // Se estiver utilizando o ProfileProvider, podemos configurar o controlador do mapa lá
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.setMapController(mapController); // Definindo o controlador do mapa
    profileProvider.moveToCurrentLocation(_currentLocation); // Movendo para a localização

    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation, 15),
    );
  }

  // Função para receber a localização do navegador
  void _getLocationFromBrowser() {
    html.window.onMessage.listen((event) {
      final data = event.data;
      if (data != null && data['lat'] != null && data['lng'] != null) {
        final lat = data['lat'];
        final lng = data['lng'];
        _updateMapLocation(lat, lng);
      }
    });
  }

  // Atualiza o mapa com a localização recebida
  void _updateMapLocation(double lat, double lng) {
    setState(() {
      _currentLocation = LatLng(lat, lng);
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('trackonnections'),
          position: _currentLocation,
          infoWindow: const InfoWindow(title: 'Trackonnections'),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });

    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Chama o método da superclasse para manter o estado

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
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Mantém a tela viva mesmo ao mudar de aba
}

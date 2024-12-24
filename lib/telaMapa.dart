import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'profile_provider.dart';

class MusicMapScreen extends StatefulWidget {
  const MusicMapScreen({Key? key}) : super(key: key);

  @override
  State<MusicMapScreen> createState() => _MusicMapScreenState();
}

class _MusicMapScreenState extends State<MusicMapScreen> with AutomaticKeepAliveClientMixin {
  late GoogleMapController mapController;
  LatLng? _currentLocation;
  final List<Marker> _markers = [];
  final Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // Inicializa a localização do dispositivo
  Future<void> _initializeLocation() async {
    await _getDeviceLocation();
  }

  // Obtém a localização do dispositivo
  Future<void> _getDeviceLocation() async {
    if (await Geolocator.isLocationServiceEnabled()) {
      PermissionStatus permissionStatus = await Permission.location.request();

      if (permissionStatus.isDenied || permissionStatus.isRestricted) {
        _showLocationPermissionDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _circles.clear();
        _circles.add(
          Circle(
            circleId: CircleId('hotspot-circle'),
            center: _currentLocation!,
            radius: 10000,
            fillColor: Colors.blue.withOpacity(0.3),
            strokeColor: Colors.blue,
            strokeWidth: 2,
            onTap: _onHotspotTap, // Exibe a música ao tocar no círculo
          ),
        );
      });

      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15),
      );
    } else {
      _showLocationServiceDialog();
    }
  }

  // Exibe o diálogo de permissão de localização
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permissão de Localização'),
          content: const Text('Este app precisa acessar sua localização para exibir o mapa. Você deseja permitir?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Permitir'),
              onPressed: () async {
                Navigator.of(context).pop();
                final status = await Permission.location.request();
                if (status.isGranted) {
                  _getDeviceLocation();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Exibe o diálogo de serviço de localização desativado
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Serviço de Localização Desativado'),
          content: const Text('Por favor, ative o serviço de localização para acessar o mapa.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Abrir Configurações'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Exibe o pop-up com o nome da música
  void _onHotspotTap() {
    _showMusicNamePopup();
  }

  // Função para exibir o nome da música tocando
  void _showMusicNamePopup() {
    final musicName = Provider.of<ProfileProvider>(context, listen: false).currentSongName;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Música Tocando'),
          content: Text('A música tocando é: $musicName'),
          actions: <Widget>[
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha apenas o pop-up
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_currentLocation == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: null,
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation!,
          zoom: 15,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: Set<Marker>.of(_markers),
        circles: _circles,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:trackonnections/profile_provider.dart';

class MusicMapScreen extends StatefulWidget {
  const MusicMapScreen({Key? key}) : super(key: key);

  @override
  State<MusicMapScreen> createState() => _MusicMapScreenState();
}

class _MusicMapScreenState extends State<MusicMapScreen> with AutomaticKeepAliveClientMixin {
  late MapController mapController;
  LatLng? _currentLocation;
  final List<Marker> _markers = [];
  final List<CircleMarker> _circleMarkers = [];

  double _currentZoom = 12.0; // Zoom inicial
  final double _minZoom = 3.0; // Zoom mínimo permitido
  final double _maxZoom = 18.0; // Zoom máximo permitido

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _initializeLocation(); // Inicializa a localização assim que a tela for carregada
  }

  Future<void> _initializeLocation() async {
    await _getDeviceLocation();
  }

  Future<void> _getDeviceLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serviço de localização desativado. Ative-o para usar o mapa.')));

      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);

        // Atualiza os marcadores
        _markers.clear();
        _markers.add(
          Marker(
            point: _currentLocation!,
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () {
                _showMusicDialog();
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purpleAccent.withOpacity(0.7),
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );

        // Atualiza os círculos
        _circleMarkers.clear();
        _circleMarkers.add(
          CircleMarker(
            point: _currentLocation!,
            color: Colors.purpleAccent.withOpacity(0.15),
            borderColor: Colors.purpleAccent.withOpacity(0.15),
            borderStrokeWidth: 2,
            useRadiusInMeter: true,
            radius: 100, // Raio em metros
          ),
        );

        // Move o mapa para a localização atual
        mapController.move(_currentLocation!, _currentZoom);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter a localização: $e')))
      ;
    }
  }

  void _showMusicDialog() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    // Atualiza a música atual no perfil
    profileProvider.setCurrentlyPlayingTrack(
      profileProvider.currentSongArtist,
      profileProvider.currentSongName,
      profileProvider.albumArtUrl as Map<String, dynamic>,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Música Tocando"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profileProvider.currentSongName != null && profileProvider.currentSongArtist != null
                    ? "${profileProvider.currentSongName} - ${profileProvider.currentSongArtist}"
                    : "Nenhuma música tocando",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Icon(
                Icons.music_note,
                size: 48,
                color: Colors.purpleAccent,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? LatLng(0.0, 0.0), // Corrigido para center
              initialZoom: _currentZoom, // Corrigido para zoom
              minZoom: _minZoom,
              maxZoom: _maxZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://a.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: _markers,
              ),
              CircleLayer(
                circles: _circleMarkers,
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  color: Colors.black,
                  onPressed: () {
                    if (_currentZoom < _maxZoom) {
                      setState(() {
                        _currentZoom++;
                      });
                      if (_currentLocation != null) {
                        mapController.move(_currentLocation!, _currentZoom);
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  color: Colors.black,
                  onPressed: () {
                    if (_currentZoom > _minZoom) {
                      setState(() {
                        _currentZoom--;
                      });
                      if (_currentLocation != null) {
                        mapController.move(_currentLocation!, _currentZoom);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class MusicMapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> musicLocations;

  const MusicMapScreen({
    Key? key,
    required this.musicLocations,
  }) : super(key: key);

  @override
  State<MusicMapScreen> createState() => _MusicMapScreenState();
}

class _MusicMapScreenState extends State<MusicMapScreen> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();

    // Configuração inicial do mapa
    _mapController = MapController(
      initPosition: widget.musicLocations.isNotEmpty
          ? GeoPoint(
              latitude: widget.musicLocations[0]['location'].latitude,
              longitude: widget.musicLocations[0]['location'].longitude,
            )
          : GeoPoint(latitude: -23.5505, longitude: -46.6333), // Posição padrão
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addInitialMarkers();
      _zoomToLocation(); // Aplica o zoom na primeira localização com a rua visível
    });
  }

  Future<void> _addInitialMarkers() async {
    for (var music in widget.musicLocations) {
      if (music['location'] != null && music['location'] is GeoPoint) {
        final GeoPoint location = music['location'];
        try {
          await _mapController.addMarker(
            location,
            markerIcon: const MarkerIcon(
              icon: Icon(Icons.location_on, color: Colors.purple, size: 48),
            ),
          );
        } catch (e) {
          debugPrint('Erro ao adicionar marcador: $e');
        }
      }
    }
  }

  // Função para zoom na primeira localização
  void _zoomToLocation() {
    if (widget.musicLocations.isNotEmpty) {
      final GeoPoint firstLocation = widget.musicLocations[0]['location'];
      _mapController.goToLocation(firstLocation); // Move a localização
      // Não define zoom no início, já que queremos que seja o zoom padrão
    }
  }

  // Função para zoom no ponto de localização atual
  void _zoomToCurrentLocation() {
    if (widget.musicLocations.isNotEmpty) {
      final GeoPoint firstLocation = widget.musicLocations[0]['location'];
      _mapController.goToLocation(firstLocation); // Move a localização
      _mapController.setZoom(zoomLevel: 15.0); // Ajusta o zoom para mostrar a rua
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        automaticallyImplyLeading: false, // Remove a setinha de voltar
        title: const SizedBox.shrink(), // Removendo o texto da AppBar
        centerTitle: true,
        elevation: 0,
      ),
      body: OSMFlutter(
        controller: _mapController,
        osmOption: const OSMOption(
          userTrackingOption: UserTrackingOption(
            enableTracking: false, // Não usa posição do usuário
          ),
        ),
        onGeoPointClicked: (geoPoint) async {
          debugPrint(
            "Marcador clicado: Latitude: ${geoPoint.latitude}, Longitude: ${geoPoint.longitude}",
          );
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Marcador Selecionado"),
                content: Text(
                  "Latitude: ${geoPoint.latitude}\nLongitude: ${geoPoint.longitude}",
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
        },
      ),
      floatingActionButton: MouseRegion(
        onEnter: (_) => setState(() {}),
        child: FloatingActionButton(
          onPressed: _zoomToCurrentLocation, // Aumenta o zoom para 15
          backgroundColor: const Color(0xFF6A1B9A),
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

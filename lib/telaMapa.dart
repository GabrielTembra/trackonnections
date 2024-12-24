import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

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

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _initializeLocation(); // Tenta inicializar a localização assim que a tela for carregada
  }

  // Função para inicializar a localização
  Future<void> _initializeLocation() async {
    await _getDeviceLocation();
  }

  // Função para obter a localização do dispositivo
  Future<void> _getDeviceLocation() async {
    if (await Geolocator.isLocationServiceEnabled()) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _markers.clear();
          _markers.add(
            Marker(
              point: _currentLocation!,
              width: 80,
              height: 80,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.15),
                ),
              ),
            ),
          );

          _circleMarkers.clear();
          _circleMarkers.add(
            CircleMarker(
              point: _currentLocation!,
              color: Colors.blue.withOpacity(0.15),
              borderColor: Colors.blue.withOpacity(0.15),
              borderStrokeWidth: 2,
              useRadiusInMeter: true,
              radius: 100, // Raio em metros
            ),
          );
        });

        // Atualiza a posição da câmera para a localização atual
        mapController.move(_currentLocation!, _currentZoom);
      } catch (e) {
        // Em vez de exibir o pop-up, você pode tratar o erro de forma silenciosa ou logá-lo
        print('Erro ao obter a localização: $e');
      }
    } else {
      // Em vez de mostrar o pop-up, você pode apenas logar ou agir de outra maneira
      print('Serviço de localização desativado');
    }
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
              initialCenter: _currentLocation ?? LatLng(0.0, 0.0),
              minZoom: _currentZoom, // Defina o nível de zoom inicial
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
          // Adicionando os ícones de zoom sem BottomAppBar
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  color: Colors.black, // Cor personalizada para o ícone de zoom in
                  onPressed: () {
                    setState(() {
                      _currentZoom++;
                    });
                    mapController.move(_currentLocation!, _currentZoom); // Ajuste do zoom
                  },
                ),
                const SizedBox(height: 10), // Espaço entre os ícones
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  color: Colors.black, // Cor personalizada para o ícone de zoom out
                  onPressed: () {
                    setState(() {
                      _currentZoom--;
                    });
                    mapController.move(_currentLocation!, _currentZoom); // Ajuste do zoom
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

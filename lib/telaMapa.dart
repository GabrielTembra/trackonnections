import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart'; // Importando o pacote location para a geolocalização
import 'package:permission_handler/permission_handler.dart'; // Importando o permission_handler
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
  final Set<Circle> _circles = {}; // Conjunto para armazenar os círculos (Hotspot)
  late LocationData _locationData;

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

    // Solicitar permissão de localização usando o permission_handler
    final status = await Permission.location.request();

    if (status.isDenied) {
      // Se a permissão for negada, mostra um alerta
      _showLocationPermissionDialog();
      return;
    }

    if (status.isPermanentlyDenied) {
      // Se a permissão for permanentemente negada, pede para abrir as configurações
      openAppSettings();
      return;
    }

    // Agora que a permissão foi concedida, podemos acessar a localização
    _locationData = await location.getLocation();

    setState(() {
      _currentLocation = LatLng(_locationData.latitude!, _locationData.longitude!);
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('trackonnections'),
          position: _currentLocation,
          infoWindow: const InfoWindow(title: 'Trackonnections'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Usando uma cor personalizada para destacar o hotspot
        ),
      );

      // Adicionando o círculo para representar a precisão
      _circles.add(
        Circle(
          circleId: CircleId('hotspot-circle'),
          center: _currentLocation,
          radius: _locationData.accuracy!, // Precisão do GPS (em metros)
          fillColor: Colors.blue.withOpacity(0.3), // Cor do preenchimento
          strokeColor: Colors.blue, // Cor da borda
          strokeWidth: 2, // Largura da borda
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

  // Função para exibir o diálogo de permissão de localização
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
                  _getDeviceLocation(); // Tentar acessar a localização novamente após a permissão
                }
              },
            ),
          ],
        );
      },
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Atualizando o ícone para destacar
        ));

      // Atualizando o círculo para refletir a nova localização
      _circles.clear();
      _circles.add(
        Circle(
          circleId: CircleId('hotspot-circle'),
          center: _currentLocation,
          radius: 50.0, // Definindo um raio fixo para o exemplo
          fillColor: Colors.blue.withOpacity(0.3),
          strokeColor: Colors.blue,
          strokeWidth: 2,
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
      appBar: null, // Remover a AppBar
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 15,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: Set<Marker>.of(_markers),
        circles: _circles, // Adicionando os círculos ao mapa (Hotspot)
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Mantém a tela viva mesmo ao mudar de aba
}

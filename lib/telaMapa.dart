import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
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
      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({Key? key}) : super(key: key);

  @override
  _MainTabScreenState createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trackonnections'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mapa'),
            Tab(text: 'Outras Funcionalidades'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MusicMapScreen(), // Mapa
          OtherScreen(), // Outra tela
        ],
      ),
    );
  }
}

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
    // Atualize a localização ao inicializar
    _initializeLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Chama a atualização da localização sempre que a tela for reconstruída
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (profileProvider.latitude != 0.0 && profileProvider.longitude != 0.0) {
      setState(() {
        _currentLocation = LatLng(profileProvider.latitude, profileProvider.longitude);
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
    } else {
      await _getDeviceLocation();
    }
  }

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

    Provider.of<ProfileProvider>(context, listen: false).saveProfileData(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
    );

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

class OtherScreen extends StatelessWidget {
  const OtherScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Outras Funcionalidades Aqui'),
    );
  }
}

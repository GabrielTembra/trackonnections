import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js' as js;

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
  _MusicMapScreenState createState() => _MusicMapScreenState();
}

class _MusicMapScreenState extends State<MusicMapScreen> {
  final List<Map<String, dynamic>> musicLocations = [
    {'name': 'Local 1', 'latitude': 51.5074, 'longitude': -0.1278},
    {'name': 'Local 2', 'latitude': 51.5155, 'longitude': -0.1420},
    {'name': 'Local 3', 'latitude': 51.5194, 'longitude': -0.1340},
  ];

  // Método para invocar a função JavaScript
  void _initializeMap() {
    final markersData = musicLocations.map((location) {
      return {
        'name': location['name'],
        'latitude': location['latitude'],
        'longitude': location['longitude'],
      };
    }).toList();

    // Passa os dados de marcador para o JavaScript usando o método call
    js.context.callMethod('initializeLeafletMap', ['map', 51.5074, -0.1278, 13, markersData]);
  }

  @override
  void initState() {
    super.initState();
    // Inicializa o mapa após o estado ser carregado
    _initializeMap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Map')),
      body: SizedBox.expand(
        child: HtmlElementView(viewType: 'map'), // Este é o contêiner do mapa
      ),
    );
  }
}

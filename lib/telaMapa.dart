import 'package:flutter/material.dart';
import 'dart:html' as html; // Importa o pacote HTML para manipular o iframe
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() {
  setUrlStrategy(PathUrlStrategy());  // Permite que o navegador use URLs "limpas" sem hashes.
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
  // Lista de locais estáticos de música
  final List<Map<String, dynamic>> musicLocations = [
    {
      'name': 'Local 1',
      'latitude': 51.5074,
      'longitude': -0.1278,
    },
    {
      'name': 'Local 2',
      'latitude': 51.5155,
      'longitude': -0.1420,
    },
    {
      'name': 'Local 3',
      'latitude': 51.5194,
      'longitude': -0.1340,
    },
    // Adicione mais locais conforme necessário
  ];

  // Gerar o HTML com mapa e locais
  String _generateMapHTML() {
    String markers = "";
    for (var location in musicLocations) {
      markers += """
        L.marker([${location['latitude']}, ${location['longitude']}])
          .addTo(map)
          .bindPopup('<b>${location['name']}</b><br>Lat: ${location['latitude']}<br>Lon: ${location['longitude']}')
      """;
    }

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <title>Music Map</title>
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css" />
        <script src="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js"></script>
        <script>
          var map = L.map('map').setView([51.509, -0.128], 12); // Posição inicial do mapa (Londres)

          // Adicionar tiles do OpenStreetMap
          L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          }).addTo(map);

          // Adicionar marcadores
          $markers
        </script>
      </head>
      <body>
        <div id="map" style="height: 100%;"></div>
      </body>
      </html>
    ''';
  }

  // Registrar o HTML do mapa no navegador
  @override
  void initState() {
    super.initState();

    // Adicionar o iframe com o conteúdo gerado pelo HTML
    final iframeElement = html.IFrameElement()
      ..srcdoc = _generateMapHTML()  // Insira o HTML gerado aqui
      ..style.border = 'none'
      ..width = '100%'
      ..height = '100%';
    
    // Registrar o viewType para ser utilizado no HtmlElementView
    html.document.getElementById('map')?.append(iframeElement);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Music Locations on Map"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            height: 500,  // Ajuste o tamanho conforme necessário
            child: HtmlElementView(
              viewType: 'map',  // Define o viewType registrado
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:html' as html;

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

  String _generateMapHTML() {
    String markers = '';
    for (var location in musicLocations) {
      markers += """
        new google.maps.Marker({
          position: {lat: ${location['latitude']}, lng: ${location['longitude']}},
          map: map,
          title: '${location['name']}'
        });
      """;
    }

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <title>Music Map</title>
        <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCdXPkH0L5txsBvmI0FAOepZpMWufrpIRY&callback=initMap" async defer></script>
        <script>
          var map;
          function initMap() {
            map = new google.maps.Map(document.getElementById("map"), {
              center: {lat: 51.5074, lng: -0.1278},
              zoom: 13,
            });

            // Adicionar marcadores
            $markers
          }
        </script>
      </head>
      <body>
        <div id="map" style="height: 100%; width: 100%;"></div>
      </body>
      </html>
    ''';
  }

  @override
  void initState() {
    super.initState();
    final iframeElement = html.IFrameElement()
      ..srcdoc = _generateMapHTML()
      ..style.border = 'none'
      ..width = '100%'
      ..height = '500px';

    html.document.body!.append(iframeElement);
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
            child: HtmlElementView(viewType: 'map'),
          ),
        ),
      ),
    );
  }
}

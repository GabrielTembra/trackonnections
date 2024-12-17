import 'dart:convert';  // Importar para converter JSON
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:http/http.dart' as http;

class MusicMapScreen extends StatefulWidget {
  MusicMapScreen({Key? key, required List musicLocations}) : super(key: key);

  @override
  _MusicMapScreenState createState() => _MusicMapScreenState();
}

class _MusicMapScreenState extends State<MusicMapScreen> {
  late MapboxMapController mapController;
  final String mapboxAccessToken = 'pk.eyJ1IjoidGVtYnJhIiwiYSI6ImNtNHNrNzN3cTAxb3gyanExdmYycW4yNDcifQ.iPyB8Yl_WTd2wJ1Fr0vTnQ'; // Coloque seu token aqui
  late List<Map<String, dynamic>> musicLocations = [];

  @override
  void initState() {
    super.initState();
    _fetchMusicLocations();  // Carregar locais de música quando a tela for inicializada
  }

  // Função para buscar dados da API
  Future<void> _fetchMusicLocations() async {
    final url = 'https://suaapi.com/musica/localizacao';  // Substitua pela URL real da sua API
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);  // Decodifica o JSON da resposta
      setState(() {
        musicLocations = List<Map<String, dynamic>>.from(data['locations']);
      });
    } else {
      throw Exception('Falha ao carregar locais de música');
    }
  }

  // Função para mover o mapa para uma localização específica
  void _moveToLocation(double latitude, double longitude) {
    mapController.animateCamera(CameraUpdate.newLatLng(LatLng(latitude, longitude)));
  }

  // Função para adicionar marcador no mapa
  void _addMarker(double latitude, double longitude) {
    mapController.addSymbol(
      SymbolOptions(
        geometry: LatLng(latitude, longitude),
        iconImage: 'assets/location_icon.png', // Substitua pelo ícone desejado
        iconSize: 1.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Music Locations on Map"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 4,
      ),
      body: musicLocations.isEmpty
          ? Center(child: CircularProgressIndicator())  // Mostrar um indicador de carregamento
          : Stack(
              children: [
                MapboxMap(
                  accessToken: mapboxAccessToken,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(51.509, -0.128), // Posição inicial de exemplo (London)
                    zoom: 13.0,
                  ),
                  onMapCreated: (MapboxMapController controller) {
                    mapController = controller;
                  },
                  onStyleLoadedCallback: () {
                    // Adiciona marcadores ao carregar o mapa
                    musicLocations.forEach((location) {
                      _addMarker(location['latitude'], location['longitude']);
                    });
                  },
                ),
                // Lista de locais de música
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 250,
                    child: ListView.builder(
                      itemCount: musicLocations.length,
                      itemBuilder: (context, index) {
                        var location = musicLocations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            title: Text(
                              location['name'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            subtitle: Text(
                              "Lat: ${location['latitude']}, Lon: ${location['longitude']}",
                              style: TextStyle(color: Colors.black54),
                            ),
                            leading: Icon(
                              Icons.location_on,
                              color: Colors.deepPurple.shade300,
                            ),
                            tileColor: Colors.deepPurple.shade100,
                            onTap: () {
                              // Mover o mapa para a localização ao tocar na lista
                              _moveToLocation(location['latitude'], location['longitude']);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

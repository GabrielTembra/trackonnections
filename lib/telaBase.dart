import 'package:flutter/material.dart';
import 'package:trackonnections/telaMapa.dart';
import 'package:trackonnections/telaSpotify.dart'; // Importe a tela de integração com Spotify
import 'package:trackonnections/telaReconhecimento.dart'; // Importe a tela de reconhecimento de música
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart'; // Pacote do mapa OSM

void main() {
  runApp(const TrackonnectionsApp());
}

class TrackonnectionsApp extends StatelessWidget {
  const TrackonnectionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trackonnections',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF6A1B9A), // Cor roxa
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Roboto'), // Texto branco com fonte Roboto
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Índice para controle de navegação entre as telas

  // Lista de telas que serão gerenciadas pelo Bottom App Bar
  final List<Widget> _screens = [
    const SpotifyAuthScreen(), // Tela de integração com Spotify
    MusicMapScreen(
      musicLocations: [
        {'name': 'Local de Música 1', 'location': GeoPoint(latitude: -23.5505, longitude: -46.6300)},
        {'name': 'Local de Música 2', 'location': GeoPoint(latitude: -23.5500, longitude: -46.6350)},
      ],
    ),
    AudioRecorder(onStop: (String path) {}), // Tela de reconhecimento de música
  ];

  // Nomes das telas que aparecerão abaixo dos ícones no Bottom App Bar
  final List<String> _screenNames = [
    'Spotify', // Nome da tela de Spotify
    'Mapa',     // Nome da tela de Mapa
    'Reconhecimento', // Nome da tela de Reconhecimento de Música
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Atualiza o índice da tela selecionada
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.music_note, color: Colors.white), // Ícone de fone de ouvido
            SizedBox(width: 8),
            Text(
              'Trackonnections',
              style: TextStyle(
                fontFamily: 'Roboto', // Usando a fonte Roboto
                fontWeight: FontWeight.bold,
                color: Colors.white, // Letra branca
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6A1B9A), // Cor roxa
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Ícone de seta personalizada
          onPressed: () {
            Navigator.pop(context); // Volta para a tela anterior
          },
        ),
      ),
      body: _screens[_selectedIndex], // Exibe a tela com base no índice selecionado
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF6A1B9A),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Ajuste do alinhamento para deixar os ícones mais próximos
          children: [
            _buildNavItem(Icons.music_note, 0), // Ícone de música
            _buildNavItem(Icons.map, 1),        // Ícone de mapa
            _buildNavItem(Icons.mic, 2),        // Ícone de microfone
          ],
        ),
      ),
    );
  }

  // Método para construir cada item no BottomAppBar
  Widget _buildNavItem(IconData icon, int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: Colors.white,
            size: 24, // Ajuste do tamanho dos ícones
          ),
          onPressed: () {
            _onItemTapped(index); // Vai para a tela correspondente
          },
        ),
        Text(
          _screenNames[index], // Nome da tela abaixo do ícone
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10, // Ajuste do texto
          ),
        ),
      ],
    );
  }
}

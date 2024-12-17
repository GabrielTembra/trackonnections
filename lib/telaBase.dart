import 'package:flutter/material.dart';
import 'package:trackonnections/telaMapa.dart';
import 'package:trackonnections/telaPerfil.dart';
import 'package:trackonnections/telaSpotify.dart';
import 'package:trackonnections/telaReconhecimento.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'dart:typed_data'; // Para manipular a imagem em bytes
import 'package:shared_preferences/shared_preferences.dart'; // Para SharedPreferences
import 'dart:convert'; // Para converter base64

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
        scaffoldBackgroundColor: const Color(0xFF6A1B9A),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
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
  int _selectedIndex = 0;
  Uint8List? _profileImageBytes; // Variável para armazenar a imagem em bytes
  Color _profileColor = Colors.deepPurple; // Cor inicial para o perfil

  final List<Widget> _screens = [
    const SpotifyAuthScreen(),
    MusicMapScreen(
      musicLocations: [
        {'name': 'Local de Música 1', 'location': GeoPoint(latitude: -23.5505, longitude: -46.6300)},
        {'name': 'Local de Música 2', 'location': GeoPoint(latitude: -23.5500, longitude: -46.6350)},
      ],
    ),
    AudioRecorder(onStop: (String path) {}),
  ];

  final List<String> _screenNames = ['Spotify', 'Mapa', 'Reconhecimento'];

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Carregar os dados salvos no SharedPreferences
  }

  // Função para carregar a imagem e a cor do perfil do SharedPreferences
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    // Carregar a imagem de perfil (base64)
    String? base64Image = prefs.getString('profile_image');
    if (base64Image != null) {
      setState(() {
        _profileImageBytes = base64Decode(base64Image); // Converte de volta para bytes
      });
    }

    // Carregar a cor de perfil
    String? colorHex = prefs.getString('profile_color');
    if (colorHex != null) {
      setState(() {
        _profileColor = Color(int.parse('0x$colorHex')); // Converte de volta para a cor
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Função para navegar para a tela de personalização de perfil
  void _goToProfileScreen(BuildContext context) {
    // Exibe o SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil clicado!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );

    // Navegar para a tela de personalização de perfil
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomizeProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.music_note, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Trackonnections',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // Foto de perfil ou ícone de pessoa
          GestureDetector(
            onTap: () => _goToProfileScreen(context), // Chama a função de navegação
            child: CircleAvatar(
              backgroundColor: _profileColor, // Cor de fundo do avatar, que é a cor do perfil
              radius: 20,
              backgroundImage: _profileImageBytes != null
                  ? MemoryImage(_profileImageBytes!) // Exibe a imagem em bytes
                  : null, // Não exibe imagem se não houver foto
              child: _profileImageBytes == null
                  ? Icon(Icons.person, color: _profileColor) // Ícone de pessoa com a cor de perfil
                  : null, // Caso tenha imagem, não mostra o ícone
            ),
          ),
          const SizedBox(width: 16), // Espaço entre o ícone e a borda
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF6A1B9A),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.music_note, 0),
            _buildNavItem(Icons.map, 1),
            _buildNavItem(Icons.mic, 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            _onItemTapped(index);
          },
        ),
        Text(
          _screenNames[index],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:trackonnections/telaMapa.dart';
import 'package:trackonnections/telaPerfil.dart';
import 'package:trackonnections/telaSpotify.dart';
import 'package:trackonnections/telaReconhecimento.dart';
import 'package:trackonnections/profile_provider.dart'; // Importe o ProfileProvider aqui
import 'dart:typed_data'; // Para manipular a imagem em bytes
import 'package:shared_preferences/shared_preferences.dart'; // Para SharedPreferences
import 'dart:convert'; // Para converter base64
import 'package:provider/provider.dart'; // Importando o Provider

void main() {
  runApp(const TrackonnectionsApp());
}

class TrackonnectionsApp extends StatelessWidget {
  const TrackonnectionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider(),
      child: MaterialApp(
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
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // Controlador de animação para o efeito de pulsação
  late AnimationController _animationController;

  final List<Widget> _screens = [
    const SpotifyAuthScreen(),
    MusicMapScreen(),
    AudioRecorder(onStop: (String path) {}),
  ];

  final List<String> _screenNames = ['Spotify', 'Mapa', 'Reconhecimento'];

  @override
  void initState() {
    super.initState();
    // Carregar os dados do perfil usando o provider
    context.read<ProfileProvider>().loadProfileData();

    // Configurar o AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // Repetir a animação
  }

  @override
  void dispose() {
    _animationController.dispose(); // Limpar o controlador ao sair
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

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
        actions: [
          // Foto de perfil ou ícone de pessoa
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomizeProfileScreen(),
              ),
            ),
            child: CircleAvatar(
              backgroundColor: profileProvider.profileColor,
              radius: 20,
              backgroundImage: profileProvider.profileImageBytes != null
                  ? MemoryImage(profileProvider.profileImageBytes!) // Se houver imagem, exibe ela
                  : null,
              child: profileProvider.profileImageBytes == null // Se não houver imagem, exibe o ícone de pessoa
                  ? const Icon(
                      Icons.person,
                      color: Colors.white, // Contraste com a cor de fundo
                      size: 20,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
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
            _buildNavItem(Icons.mic, 2, isRecording: profileProvider.isRecording),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, {bool isRecording = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: isRecording && index == 2
              ? Tween<double>(begin: 1.0, end: 1.2).animate(_animationController)
              : AlwaysStoppedAnimation(1.0),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            onPressed: () {
              _onItemTapped(index);
              if (index == 2) {
                context.read<ProfileProvider>().toggleRecording(); // Alternar gravação usando o provider
              }
            },
          ),
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

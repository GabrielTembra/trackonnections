import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:trackonnections/telaPrincipal.dart';

void main() {
  runApp(const Telalogin());
}

class Telalogin extends StatelessWidget {
  const Telalogin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrackConnections',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.deepPurple,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const LatLng _initialLocation = LatLng(-23.5505, -46.6333); // São Paulo

  // Função para abrir o mapa
  void _openMap() {
    MapsLauncher.launchCoordinates(_initialLocation.latitude, _initialLocation.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple, // Cor de fundo do AppBar roxa
        title: Row(
          children: [
            const Icon(Icons.music_note, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'TrackConnections',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white, // Título em branco
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bem-vindo ao TrackConnections',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Título em branco
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Conecte-se e descubra músicas ao seu redor!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70, // Texto abaixo do título em um tom mais claro
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Digite seu Email', // Texto dentro do campo de texto
                hintStyle: TextStyle(color: Colors.deepPurple), // Cor do texto da dica
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.mail, color: Colors.deepPurple), // Ícone de carta roxo
                filled: true,
                fillColor: Colors.white, // Cor de fundo do campo de texto
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Digite sua Senha', // Texto dentro do campo de texto
                hintStyle: TextStyle(color: Colors.deepPurple), // Cor do texto da dica
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock, color: Colors.deepPurple), // Ícone de cadeado roxo
                filled: true,
                fillColor: Colors.white, // Cor de fundo do campo de texto
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Ação do botão para navegar até a tela do mapa
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MusicTrackScreen()),
                );
              },
              child: const Text('Entrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Cor de fundo do botão branco
                foregroundColor: Colors.deepPurple, // Texto do botão em roxo
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Adicione a lógica de recuperação de senha
                print('Botão Esqueceu a Senha pressionado');
              },
              child: const Text(
                'Esqueceu a senha?',
                style: TextStyle(color: Colors.white), // Cor do texto do botão
              ),
            ),
          ],
        ),
      ),
    );
  }
}
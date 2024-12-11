import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotify/spotify.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';  // Para autenticação
import 'package:http/http.dart' as http; // Para requisições HTTP
import 'package:trackonnections/telaMapa.dart';  // Sua tela de mapa

void main() {
  runApp(const TrackConnectionsApp());
}

class TrackConnectionsApp extends StatelessWidget {
  const TrackConnectionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrackConnections',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MusicTrackScreen(accessToken: null,),
    );
  }
}

class MusicTrackScreen extends StatefulWidget {
  const MusicTrackScreen({super.key, required accessToken});

  @override
  State<MusicTrackScreen> createState() => _MusicTrackScreenState();
}

class _MusicTrackScreenState extends State<MusicTrackScreen> {
  late SpotifyApi _spotify;
  String _currentTrack = 'Nenhuma música tocando';
  String _artistName = 'Desconhecido';
  LatLng _currentLocation = const LatLng(-23.5505, -46.6333); // São Paulo
  String _accessToken = '';

  @override
  void initState() {
    super.initState();
    _authenticateSpotify(); // Iniciar o processo de autenticação ao iniciar
    _getCurrentLocation();  // Obter localização
  }

  // Função de autenticação com Spotify usando OAuth
  Future<void> _authenticateSpotify() async {
    try {
      // URL de autenticação do Spotify com o URI de redirecionamento correto
      final authUrl = Uri.parse(
        'https://accounts.spotify.com/authorize?response_type=code&client_id=b0620bb044c64d529f747bb52b7233c2&redirect_uri=trackonnections://callback&scope=user-read-playback-state user-read-currently-playing',
      );

      // Usando o Flutter Web Auth para autenticar o usuário
      final result = await FlutterWebAuth.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'trackonnections', // A URL de esquema personalizada
      );

      // Pegue o código de autenticação da URL
      final code = Uri.parse(result).queryParameters['code'];

      // Agora, você deve trocar o código por um token de acesso
      final tokenResponse = await _getAccessToken(code!);

      setState(() {
        _accessToken = tokenResponse['access_token'];
      });

      // Agora, o token está disponível para fazer chamadas na API do Spotify
      _spotify = SpotifyApi(SpotifyApiCredentials(
        'b0620bb044c64d529f747bb52b7233c2', // Seu clientId
        '6d197dce2d0a4874a49de7ddcea781b7', // Seu clientSecret
      ));

      _getCurrentTrack();
    } catch (e) {
      print('Erro de autenticação com Spotify: $e');
    }
  }

  // Função para trocar o código de autenticação por um token de acesso
  Future<Map<String, dynamic>> _getAccessToken(String code) async {
    final tokenUrl = Uri.parse('https://accounts.spotify.com/api/token');
    final response = await http.post(
      tokenUrl,
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': 'trackonnections://callback', // Usando o mesmo URI registrado
        'client_id': 'b0620bb044c64d529f747bb52b7233c2',
        'client_secret': '6d197dce2d0a4874a49de7ddcea781b7',
      },
    );

    // Verifica se a resposta foi bem-sucedida
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao obter o token de acesso');
    }
  }

  // Função para pegar a música atual
  Future<void> _getCurrentTrack() async {
    if (_accessToken.isNotEmpty) {
      try {
        final credentials = SpotifyApiCredentials(
          'b0620bb044c64d529f747bb52b7233c2', // Seu clientId
          '6d197dce2d0a4874a49de7ddcea781b7', // Seu clientSecret
        );
        final spotify = SpotifyApi(credentials);
        final currentlyPlaying = await spotify.player.currentlyPlaying();

        if (currentlyPlaying != null && currentlyPlaying.item != null) {
          final track = currentlyPlaying.item as Track;
          setState(() {
            _currentTrack = track.name!;
            _artistName = track.artists?.first.name ?? 'Desconhecido';
          });
        } else {
          setState(() {
            _currentTrack = 'Nenhuma música tocando';
            _artistName = 'Desconhecido';
          });
        }
      } catch (e) {
        print('Erro ao obter a música atual: $e');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Erro ao obter a localização: $e');
    }
  }

  // Função para abrir a tela do mapa
  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicMapScreen(
          currentLocation: _currentLocation,
          musicLocations: [
            {'location': _currentLocation, 'name': 'Música Atual'},
          ],
        ),
      ),
    );
  }

  // Função para voltar à tela anterior após autenticação
  void _navigateBack() {
    Navigator.pop(context); // Voltar para a tela anterior
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Row(
          children: const [
            Icon(Icons.music_note, color: Colors.white),
            SizedBox(width: 8),
            Text('Música no Local Atual'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Música Tocando: $_currentTrack',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Artista: $_artistName',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.deepPurple[900],
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      _authenticateSpotify(); // Chama a função de autenticação
                    },
                    child: const Text('Conectar ao Spotify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _openMap,
                    child: const Text('Abrir Mapa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _navigateBack, // Voltar para a tela anterior
                    child: const Text('Voltar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/models/track.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

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
      home: const MusicMapScreen(),
    );
  }
}

class MusicMapScreen extends StatefulWidget {
  const MusicMapScreen({super.key});

  @override
  State<MusicMapScreen> createState() => _MusicMapScreenState();
}

class _MusicMapScreenState extends State<MusicMapScreen> {
  final LatLng _initialLocation = const LatLng(-23.5505, -46.6333); // São Paulo
  bool _isConnected = false;
  String _currentTrack = 'Nenhuma música tocando';

  StreamSubscription? _uniLinksSubscription;

  @override
  void initState() {
    super.initState();
    _initUniLinks();
    _connectToSpotify();
  }

  @override
  void dispose() {
    _uniLinksSubscription?.cancel();
    super.dispose();
  }

  /// Inicializa o listener para os Deep Links
  Future<void> _initUniLinks() async {
    // Para links recebidos enquanto o app já está aberto
    _uniLinksSubscription = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      print('Erro ao processar Deep Link: $err');
    });

    // Para links que abriram o app desde o início
    try {
      final Uri? initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      print('Erro ao obter o Deep Link inicial: $e');
    }
  }

  /// Trata os Deep Links recebidos
  void _handleDeepLink(Uri uri) {
    if (uri.host == 'callback') {
      print('Deep Link recebido: $uri');

      // Processa os dados do URI (se necessário)
      final token = uri.queryParameters['token']; // Exemplo de extração de parâmetro
      print('Token recebido: $token');

      // Atualiza o estado para refletir que a conexão foi bem-sucedida
      setState(() {
        _isConnected = true; // Marca como conectado ao Spotify
      });

      // Realiza qualquer ação necessária após a conexão, por exemplo:
      _getCurrentTrack(); // Obtém a música atual ou atualiza algum outro estado.
    }
  }

  /// Conecta ao Spotify
  Future<void> _connectToSpotify() async {
    try {
      bool result = await SpotifySdk.connectToSpotifyRemote(
        clientId: 'b0620bb044c64d529f747bb52b7233c2', // Substitua pelo seu Client ID
        redirectUrl: 'trackonnections://callback', // Esquema de redirecionamento atualizado
      );
      setState(() {
        _isConnected = result;
      });
    } catch (e) {
      print('Erro ao conectar ao Spotify: $e');
    }
  }

  /// Obtém informações da música atual
  Future<void> _getCurrentTrack() async {
    if (_isConnected) {
      try {
        PlayerState? playerState = await SpotifySdk.getPlayerState();
        Track? track = playerState?.track;
        setState(() {
          _currentTrack = track != null
              ? '${track.name} - ${track.artist.name}'
              : 'Nenhuma música tocando';
        });
      } catch (e) {
        print('Erro ao obter a música atual: $e');
      }
    } else {
      print('Conexão ao Spotify não estabelecida');
    }
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
            Text(
              'TrackConnections',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.deepPurple[100],
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    MapsLauncher.launchCoordinates(
                        _initialLocation.latitude, _initialLocation.longitude);
                  },
                  child: const Text(
                    'Abrir Mapa',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.deepPurple[50],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentTrack,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _getCurrentTrack,
                      child: const Text('Obter Música Atual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';  // Importando o pacote url_launcher

class SpotifyMusicRecognitionApp extends StatelessWidget {
  const SpotifyMusicRecognitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spotify Music Recognition',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const SpotifyMusicRecognitionScreen(),
    );
  }
}

class SpotifyMusicRecognitionScreen extends StatefulWidget {
  const SpotifyMusicRecognitionScreen({super.key});

  @override
  State<SpotifyMusicRecognitionScreen> createState() =>
      _SpotifyMusicRecognitionScreenState();
}

class _SpotifyMusicRecognitionScreenState
    extends State<SpotifyMusicRecognitionScreen> {
  String _currentTrack = 'Nenhuma música reconhecida';
  String _artistName = 'Desconhecido';
  String _trackImageUrl = '';
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _checkSpotifyAuth();
    _listenForSpotifyLink();
  }

  Future<void> _checkSpotifyAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('spotify_access_token');

    if (accessToken == null) {
      // Se não tiver token, faz login
      _loginSpotify();
    } else {
      // Se já tiver token, tenta pegar a música tocando
      _getCurrentlyPlayingTrack(accessToken);
    }
  }

  Future<void> _loginSpotify() async {
    final clientId = 'b0620bb044c64d529f747bb52b7233c2'; // Seu Client ID do Spotify
    final redirectUri = 'trackonnections://callback'; // O mesmo redirect URI configurado no Spotify Developer
    final authUrl =
        'https://accounts.spotify.com/authorize?response_type=code&client_id=$clientId&scope=user-read-playback-state&redirect_uri=$redirectUri';

    // Use launchUrl (melhor abordagem para deep linking)
    final uri = Uri.parse(authUrl);
    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    } else {
      throw 'Não foi possível abrir o link de autenticação do Spotify';
    }
  }

  // Função para processar o link de redirecionamento após o login
  Future<void> _listenForSpotifyLink() async {
    // Escuta os links profundos
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleRedirect(uri);
      }
    });

    _appLinks.uriLinkStream.listen((uri) {
      if (uri != null) {
        _handleRedirect(uri);
      }
    });
  }

  Future<void> _handleRedirect(Uri uri) async {
    if (uri.queryParameters.containsKey('code')) {
      final authCode = uri.queryParameters['code'];

      if (authCode != null) {
        // Trocar o código de autorização por um token de acesso
        await _exchangeAuthCodeForToken(authCode);
      }
    }
  }

  Future<void> _exchangeAuthCodeForToken(String authCode) async {
    final clientId = 'b0620bb044c64d529f747bb52b7233c2'; // Seu Client ID
    final clientSecret = '6d197dce2d0a4874a49de7ddcea781b7'; // Seu Client Secret
    final redirectUri = 'trackonnections://callback'; // O mesmo redirect URI configurado no Spotify
    final tokenUrl = 'https://accounts.spotify.com/api/token';

    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {
        'Authorization': 'Basic ' +
            base64Encode(utf8.encode('$clientId:$clientSecret')),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'code': authCode,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String accessToken = data['access_token'];

      // Salva o token de acesso no SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('spotify_access_token', accessToken);

      // Obtém a música tocando com o token
      _getCurrentlyPlayingTrack(accessToken);
    } else {
      print('Erro ao trocar o código por token: ${response.statusCode}');
    }
  }

  Future<void> _getCurrentlyPlayingTrack(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/player/currently-playing'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data['item'] != null) {
        setState(() {
          _currentTrack = data['item']['name'] ?? 'Nenhuma música reconhecida';
          _artistName = data['item']['artists'][0]['name'] ?? 'Desconhecido';
          _trackImageUrl = data['item']['album']['images'][0]['url'] ?? '';
        });
      } else {
        setState(() {
          _currentTrack = 'Nenhuma música reconhecida';
          _artistName = 'Desconhecido';
        });
      }
    } else {
      print('Erro ao obter a música tocando: ${response.statusCode}');
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
            Text('Reconhecimento de Música do Spotify'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_trackImageUrl.isNotEmpty)
              Image.network(
                _trackImageUrl,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 15),
            Text(
              'Música: $_currentTrack',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Artista: $_artistName',
              style: TextStyle(
                fontSize: 18,
                color: Colors.deepPurple[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

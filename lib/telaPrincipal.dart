import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

void main() {
  runApp(const SpotifyMusicRecognitionApp());
}

class SpotifyMusicRecognitionApp extends StatelessWidget {
  const SpotifyMusicRecognitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spotify Music Recognition',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFF4A148C),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Roboto', color: Colors.white),
          bodyMedium: TextStyle(fontFamily: 'Roboto', color: Colors.white),
          headlineSmall: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
  List<dynamic> _playlists = [];
  String? _accessToken;
  final FlutterAppAuth _appAuth = FlutterAppAuth();

  @override
  void initState() {
    super.initState();
    _checkSpotifyAuth();
  }

  Future<void> _checkSpotifyAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('spotify_access_token');

    if (_accessToken != null) {
      _getUserPlaylists(_accessToken!);
    }
  }

  Future<void> _loginSpotify() async {
    const clientId = 'b0620bb044c64d529f747bb52b7233c2';
    const redirectUri = 'com.spotify.musicrecognition://callback'; // Nova URI
    const authorizationEndpoint =
        'https://accounts.spotify.com/authorize';
    const tokenEndpoint = 'https://accounts.spotify.com/api/token';

    try {
      final AuthorizationTokenRequest request = AuthorizationTokenRequest(
        clientId,
        redirectUri,
        scopes: ['user-read-playback-state', 'playlist-read-private'],
      );

      // Realizando a troca do código de autorização
      final result = await _appAuth.authorizeAndExchangeCode(request);

      if (result.accessToken != null) {
        _accessToken = result.accessToken;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('spotify_access_token', _accessToken!);
        _getUserPlaylists(_accessToken!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro na autenticação com o Spotify.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao tentar autenticar.')),
      );
    }
  }

  Future<void> _getUserPlaylists(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/playlists'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _playlists = data['items'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao obter as playlists.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        title: const Text(
          'Reconhecimento de Música e Playlists',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_playlists.isEmpty)
            Expanded(
              child: Center(
                child: ElevatedButton(
                  onPressed: _loginSpotify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Login com Spotify',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  return ListTile(
                    leading: Image.network(
                      playlist['images'].isNotEmpty
                          ? playlist['images'][0]['url']
                          : '',
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.music_note),
                    ),
                    title: Text(
                      playlist['name'],
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

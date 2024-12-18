import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const SpotifyAuthScreen(),
      routes: {
        '/spotify': (context) => const SpotifyPlaylistsScreen(),
      },
    );
  }
}

class SpotifyAuthScreen extends StatefulWidget {
  const SpotifyAuthScreen({super.key});

  @override
  State<SpotifyAuthScreen> createState() => _SpotifyAuthScreenState();
}

class _SpotifyAuthScreenState extends State<SpotifyAuthScreen> {
  String? _accessToken;
  List<dynamic> _playlists = [];

  final String clientId = '4c4da1c7a8874e4996356c1792886893'; // Substitua pelo seu client_id
  final String redirectUri = 'https://trackonnections.web.app/telabase/spotify'; // URL de redirecionamento configurada no Spotify

  /// Autenticar com Spotify e obter o Access Token
  Future<void> _authenticateWithSpotify() async {
    try {
      final authUrl = Uri.https(
        'accounts.spotify.com',
        '/authorize',
        {
          'client_id': clientId,
          'response_type': 'token',
          'redirect_uri': redirectUri,
          'scope': 'playlist-read-private user-library-read user-top-read',
        },
      );

      // Usar FlutterWebAuth para autenticação
      final result = await FlutterWebAuth.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: Uri.parse(redirectUri).scheme,
      );

      // Extrair o Access Token da URL de redirecionamento
      final Uri resultUri = Uri.parse(result);
      final token = resultUri.fragment.split('&').firstWhere((element) => element.startsWith('access_token=')).split('=')[1];

      setState(() {
        _accessToken = token;
      });

      _showSuccessSnackbar('Login com Spotify realizado com sucesso!');

      // Após autenticação, navegar para a tela de playlists
      Navigator.pushReplacementNamed(context, '/spotify');
    } catch (e) {
      _showErrorSnackbar('Erro durante a autenticação com o Spotify');
      print('Authentication Error: $e');
    }
  }

  /// Exibe um snackbar de sucesso
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
    );
  }

  /// Exibe um snackbar de erro
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        automaticallyImplyLeading: false,
        title: const Text(
          'Trackonnections',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _authenticateWithSpotify,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Conectar com Spotify',
            style: TextStyle(
              color: Color(0xFF6A1B9A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class SpotifyPlaylistsScreen extends StatefulWidget {
  const SpotifyPlaylistsScreen({super.key});

  @override
  State<SpotifyPlaylistsScreen> createState() => _SpotifyPlaylistsScreenState();
}

class _SpotifyPlaylistsScreenState extends State<SpotifyPlaylistsScreen> {
  String? _accessToken;
  List<dynamic> _playlists = [];

  @override
  void initState() {
    super.initState();
    _accessToken = _getAccessToken();
    if (_accessToken != null) {
      _fetchPlaylists();
    }
  }

  String? _getAccessToken() {
    // Recupera o token de acesso do localStorage ou de onde você o armazenou
    return ModalRoute.of(context)?.settings.arguments as String?;
  }

  /// Buscar playlists do usuário
  Future<void> _fetchPlaylists() async {
    if (_accessToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/playlists'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _playlists = data['items'];
        });
      } else {
        throw Exception('Erro ao buscar playlists: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackbar('Erro ao buscar playlists');
      print('Playlist Fetch Error: $e');
    }
  }

  /// Exibe um snackbar de erro
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        title: const Text(
          'Playlists do Spotify',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: _playlists.isNotEmpty
            ? ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  return ListTile(
                    title: Text(playlist['name'], style: const TextStyle(color: Colors.white)),
                    subtitle: Text(playlist['description'] ?? 'Sem descrição', style: const TextStyle(color: Colors.white)),
                  );
                },
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

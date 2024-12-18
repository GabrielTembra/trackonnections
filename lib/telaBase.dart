import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
      home: const HomeScreen(),  // Tela base agora verifica o token
      routes: {
        '/spotify': (context) => const SpotifyPlaylistsScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _loadAccessToken();  // Verifica se o token já foi armazenado
  }

  // Função para carregar o token do Spotify armazenado
  Future<void> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _accessToken = prefs.getString('spotify_access_token');
    });
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
      body: _accessToken == null
          ? const SpotifyAuthScreen()  // Se não tiver token, exibe a tela de autenticação
          : const SpotifyPlaylistsScreen(),  // Se tiver token, exibe as playlists
    );
  }
}

class SpotifyAuthScreen extends StatefulWidget {
  const SpotifyAuthScreen({super.key});

  @override
  State<SpotifyAuthScreen> createState() => _SpotifyAuthScreenState();
}

class _SpotifyAuthScreenState extends State<SpotifyAuthScreen> {
  final String clientId = '4c4da1c7a8874e4996356c1792886893'; // Seu client_id
  final String redirectUri = 'https://trackonnections.web.app/telabase'; // URL de redirecionamento

  // Função para autenticar com Spotify e obter o Access Token
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

      // Salvar o token no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('spotify_access_token', token);

      // Navegar para a tela de playlists
      Navigator.pushReplacementNamed(context, '/spotify');
    } catch (e) {
      print('Authentication Error: $e');
      _showErrorSnackbar('Erro durante a autenticação com o Spotify');
    }
  }

  // Função para exibir um Snackbar de erro
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
    _loadAccessToken();
  }

  // Função para carregar o token do SharedPreferences
  Future<void> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _accessToken = prefs.getString('spotify_access_token');
    });

    if (_accessToken != null) {
      _fetchPlaylists();
    }
  }

  // Função para buscar playlists do Spotify
  Future<void> _fetchPlaylists() async {
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
        throw Exception('Erro ao buscar playlists');
      }
    } catch (e) {
      print('Error fetching playlists: $e');
    }
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


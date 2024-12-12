import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;

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
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFF4A148C),
      ),
      home: const SpotifyAuthScreen(),
    );
  }
}

class SpotifyAuthScreen extends StatefulWidget {
  const SpotifyAuthScreen({super.key});

  @override
  _SpotifyAuthScreenState createState() => _SpotifyAuthScreenState();
}

class _SpotifyAuthScreenState extends State<SpotifyAuthScreen> {
  String? _accessToken;

  static const String clientId = 'b0620bb044c64d529f747bb52b7233c2';
  static const String redirectUri = 'trackonnections://callback';  // URI personalizado

  final String _authUrl =
      'https://accounts.spotify.com/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&scope=playlist-modify-public playlist-modify-private user-library-read';

  // Função para iniciar o login com o Spotify
  Future<void> _launchSpotifyLogin() async {
    try {
      // Inicia o processo de autenticação via Web Auth
      final result = await FlutterWebAuth.authenticate(
        url: _authUrl,
        callbackUrlScheme: 'trackonnections',  // Define o esquema de URL personalizado
      );

      // Extrai o código de autorização do URL de retorno
      final code = Uri.parse(result).queryParameters['code'];

      if (code != null) {
        _exchangeCodeForToken(code);
      }
    } catch (e) {
      print("Erro ao autenticar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao realizar login com Spotify.')),
      );
    }
  }

  // Função para trocar o código por um token de acesso
  Future<void> _exchangeCodeForToken(String code) async {
    final clientSecret = '6d197dce2d0a4874a49de7ddcea781b7';  // Adicione o seu client secret aqui
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret')),
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _accessToken = data['access_token'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao trocar código por token.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trackonnections - Spotify'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _launchSpotifyLogin,
              child: const Text('Login com Spotify'),
            ),
            if (_accessToken != null)
              ElevatedButton(
                onPressed: () {
                  // Criar playlist ou fazer outras ações com o token
                },
                child: const Text('Criar Playlist no Spotify'),
              ),
          ],
        ),
      ),
    );
  }
}



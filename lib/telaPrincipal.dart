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
  static const String redirectUri = 'http:///callback'; // O URI de callback que o servidor Express usa
  static const String clientSecret = '6d197dce2d0a4874a49de7ddcea781b7';

  // Função para iniciar o login com o Spotify
  Future<void> _launchSpotifyLogin() async {
    final authUrl = 'https://accounts.spotify.com/authorize?'
        'client_id=$clientId&'
        'response_type=code&'
        'redirect_uri=$redirectUri&'
        'scope=user-read-playback-state%20user-read-currently-playing';

    // Usando o FlutterWebAuth para abrir o navegador e capturar o código de autorização
    final result = await FlutterWebAuth.authenticate(
      url: authUrl,
      callbackUrlScheme: 'http', // O URL que o Spotify redireciona após a autenticação
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code != null) {
      _exchangeCodeForToken(code);
    }
  }

  // Função para trocar o código de autorização pelo token de acesso
  Future<void> _exchangeCodeForToken(String code) async {
    try {
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
          const SnackBar(content: Text('Erro ao obter o token de acesso.')),
        );
      }
    } catch (e) {
      print("Erro ao trocar o código: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao trocar o código por token.')),
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
              child: const Text('Entrar no Spotify'),
            ),
            if (_accessToken != null)
              Text(
                'Token de Acesso: $_accessToken',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:spotify/spotify.dart';

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
        scaffoldBackgroundColor: const Color(0xFF4A148C),
      ),
      home: const SpotifyAuthScreen(),
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
  SpotifyApi? _spotify;

  // Definindo as variáveis diretamente no código
  final String clientId = 'b0620bb044c64d529f747bb52b7233c2'; // Substitua pelo seu client_id
  final String clientSecret = '6d197dce2d0a4874a49de7ddcea781b7'; // Substitua pelo seu client_secret
  final String redirectUri = 'https://trackonnections.firebaseapp.com/__/auth/handler'; // Substitua pelo seu redirect_uri

  /// Método para autenticar o usuário via Spotify
  Future<void> _authenticateWithSpotify() async {
    try {
      final credentials = SpotifyApiCredentials(clientId, clientSecret);
      final grant = SpotifyApi.authorizationCodeGrant(credentials);

      // Gerar a URL de autorização corretamente
      final authUrl = grant.getAuthorizationUrl(
        ['user-read-private', 'user-read-email'] as Uri, // Lista de escopos
        state: 'optionalState', // Opcional: você pode passar o parâmetro state se desejar
      );

      // Usar FlutterWebAuth para autenticação do usuário
      final result = await FlutterWebAuth.authenticate(
        url: authUrl.toString(),  // Passando a URL gerada como String
        callbackUrlScheme: Uri.parse(redirectUri).scheme, // Apenas o esquema, ex: "https"
      );

      // Extrair o código de autorização da URL de redirecionamento
      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        await _exchangeCodeForToken(code, grant);
      }
    } catch (e) {
      _showErrorSnackbar('Erro durante a autenticação com o Spotify');
      print('Authentication Error: $e');
    }
  }

  /// Troca o código de autorização pelo token de acesso
  Future<void> _exchangeCodeForToken(String code, grant) async {
    try {
      final credentials = await grant.getToken(code);
      setState(() {
        _accessToken = credentials.accessToken;
        _spotify = SpotifyApi(credentials); // Inicializar a API do Spotify apenas após o token
      });
      _showSuccessSnackbar('Login com Spotify realizado com sucesso!');
    } catch (e) {
      _showErrorSnackbar('Erro ao obter o token de acesso: $e');
      print('Token Exchange Error: $e');
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
        title: const Text('Trackonnections - Spotify'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _authenticateWithSpotify,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text('Conectar com Spotify'),
            ),
            if (_accessToken != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Token de Acesso:\n$_accessToken',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:spotify/spotify.dart';
import 'package:trackonnections/telaLogin.dart'; // Importe sua tela de login

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
        scaffoldBackgroundColor: const Color(0xFF6A1B9A), // Cor roxa
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white), // Texto branco por padrão
        ),
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
  List<PlaylistSimple> _playlists = [];

  final String clientId = 'b0620bb044c64d529f747bb52b7233c2'; // Substitua pelo seu client_id
  final String clientSecret = '6d197dce2d0a4874a49de7ddcea781b7'; // Substitua pelo seu client_secret
  final String redirectUri = 'https://trackonnections.firebaseapp.com'; // URL de redirecionamento configurada no Spotify

  /// Método para autenticar o usuário via Spotify
  Future<void> _authenticateWithSpotify() async {
    try {
      final credentials = SpotifyApiCredentials(clientId, clientSecret);
      final grant = SpotifyApi.authorizationCodeGrant(credentials);

      // Corrigindo a passagem do escopo para um único Uri
      final authUrl = grant.getAuthorizationUrl(
        Uri.parse('https://accounts.spotify.com/authorize?scope=playlist-read-private'),
      );

      // Usar FlutterWebAuth para autenticação do usuário
      final result = await FlutterWebAuth.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: Uri.parse(redirectUri).scheme,
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
        _spotify = SpotifyApi(credentials);
      });
      _showSuccessSnackbar('Login com Spotify realizado com sucesso!');

      // Após a autenticação, buscar as playlists do usuário
      await _fetchPlaylists();

      // Redirecionar para a tela de login após autenticação bem-sucedida
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Telalogin()), // Redireciona para a tela de login
      );
    } catch (e) {
      _showErrorSnackbar('Erro ao obter o token de acesso: $e');
      print('Token Exchange Error: $e');
    }
  }

  /// Método para buscar as playlists do usuário
  Future<void> _fetchPlaylists() async {
    if (_spotify != null) {
      try {
        // Usando o método correto para buscar as playlists
        final playlists = await _spotify!.playlists.me.all();
        setState(() {
          _playlists = playlists.toList();
        });
      } catch (e) {
        _showErrorSnackbar('Erro ao buscar playlists: $e');
        print('Playlist Fetch Error: $e');
      }
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
        backgroundColor: const Color(0xFF6A1B9A), // Cor roxa
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _authenticateWithSpotify,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white), // Botão branco
              child: const Text('Conectar com Spotify', style: TextStyle(color: Color(0xFF6A1B9A))), // Texto roxo
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
            if (_playlists.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Playlists do usuário:', style: TextStyle(color: Colors.white)),
              ..._playlists.map((playlist) => ListTile(
                    title: Text(playlist.name ?? 'Sem nome', style: const TextStyle(color: Colors.white)),
                    subtitle: Text(playlist.description ?? 'Sem descrição', style: const TextStyle(color: Colors.white)),
                  )) 
            ] else if (_accessToken != null)
              const Text(
                'Nenhuma playlist encontrada',
                style: TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

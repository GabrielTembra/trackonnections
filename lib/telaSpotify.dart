import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:spotify/spotify.dart';
import 'package:provider/provider.dart'; // Adicione essa importação
import 'package:trackonnections/telaLogin.dart'; // Importe sua tela de login
import 'package:trackonnections/profile_provider.dart'; // Importe seu ProfileProvider

void main() {
  runApp(const TrackonnectionsApp());
}

class TrackonnectionsApp extends StatelessWidget {
  const TrackonnectionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileProvider(), // Adicione o ProfileProvider aqui
      child: MaterialApp(
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
      ),
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

  @override
  void initState() {
    super.initState();
    // Carregar os dados do perfil assim que a tela for carregada
    _loadSpotifyCredentials();
  }

  // Função para obter as credenciais do ProfileProvider
  Future<void> _loadSpotifyCredentials() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.loadProfileData();
  }

  // Método para autenticar o usuário via Spotify
  Future<void> _authenticateWithSpotify() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    try {
      final credentials = SpotifyApiCredentials(profileProvider.clientId, profileProvider.clientSecret);
      final grant = SpotifyApi.authorizationCodeGrant(credentials);

      // Autenticar o usuário com o FlutterWebAuth
      final authUrl = grant.getAuthorizationUrl(
        Uri.parse('https://accounts.spotify.com/authorize'),
        scopes: [
          'playlist-read-private', // Permissão para ler playlists privadas
          'user-library-read', // Permissão para acessar a biblioteca do usuário
          'user-top-read' // Permissão para acessar os dados mais ouvidos
        ],
      );

      // Usar FlutterWebAuth para autenticação do usuário
      final result = await FlutterWebAuth.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'https', // Especifique o esquema 'https' diretamente
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
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.setRecordingState(true); // Exemplo de atualização do estado de gravação, se necessário

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
        backgroundColor: const Color(0xFF6A1B9A), // Cor roxa
        automaticallyImplyLeading: false, // Remove a setinha de voltar
        title: const SizedBox.shrink(), // Remove o texto do AppBar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _authenticateWithSpotify,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Cor do botão
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Tamanho do botão
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Bordas arredondadas
                ),
              ),
              child: const Text(
                'Conectar com Spotify',
                style: TextStyle(
                  color: Color(0xFF6A1B9A), // Cor do texto roxa
                  fontWeight: FontWeight.bold, // Texto em negrito
                  fontSize: 18, // Tamanho da fonte
                ),
              ),
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

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_provider.dart'; // Importe o ProfileProvider
import 'package:app_links/app_links.dart';

class SpotifyAuthScreen extends StatefulWidget {
  const SpotifyAuthScreen({super.key});

  @override
  State<SpotifyAuthScreen> createState() => _SpotifyAuthScreenState();
}

class _SpotifyAuthScreenState extends State<SpotifyAuthScreen> {
  bool _isAuthenticated = false;
  List<dynamic> _playlists = [];
  List<dynamic> _tracks = [];
  bool _isLoading = false;
  bool _isAuthAttempted = false;

  @override
  void initState() {
    super.initState();
    _initializeSpotify();
    _listenForRedirect();
  }

  // Inicializa a autenticação com o Spotify
  Future<void> _initializeSpotify() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final storedToken = profileProvider.accessToken;

      if (storedToken != null) {
        setState(() {
          _isAuthenticated = true;
        });
        await _fetchPlaylists(storedToken);
      } else if (!_isAuthAttempted) {
        await _authenticateSpotify();
      }
    } catch (e) {
      _showErrorSnackbar("Erro durante a inicialização: $e");
      debugPrint("Initialization Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Inicia o processo de autenticação
  Future<void> _authenticateSpotify() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    try {
      setState(() {
        _isAuthAttempted = true;
      });

      final authorizationUrl = Uri.https(
        'accounts.spotify.com',
        '/authorize',
        {
          'client_id': profileProvider.clientId,
          'response_type': 'code',
          'redirect_uri': profileProvider.redirectUri,
          'scope': 'playlist-read-private playlist-read-collaborative user-read-playback-state',
        },
      );

      // Lança a URL de autenticação no navegador do app sem abrir múltiplas abas
      await _launchURLInWebView(authorizationUrl.toString());
    } catch (e) {
      _showErrorSnackbar("Erro durante a autenticação: $e");
      debugPrint("Authentication Error: $e");
    }
  }

  // Lança a URL de autenticação no navegador do app sem abrir múltiplas abas
  Future<void> _launchURLInWebView(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceWebView: true, enableJavaScript: true); // Força abrir em um WebView
    } else {
      throw 'Não foi possível abrir a URL: $url';
    }
  }

  // Escuta o redirecionamento da URL após a autenticação
  Future<void> _listenForRedirect() async {
    final appLinks = AppLinks();

    // Escuta os links que o app recebe
    appLinks.uriLinkStream.listen((Uri? uri) async {
      if (uri != null && uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code']!;
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

        // Troca o código por um token de acesso
        final accessToken = await _exchangeCodeForToken(code, profileProvider);

        if (accessToken.isNotEmpty) {
          // Salva o token de acesso
          profileProvider.setAccessToken(accessToken);

          setState(() {
            _isAuthenticated = true;
          });

          // Agora, com o accessToken, faz a requisição para pegar as playlists
          await _fetchPlaylists(accessToken);
        }
      } else {
        _showErrorSnackbar("Código de autenticação não encontrado.");
      }
    });
  }

  // Troca o código por um token de acesso
  Future<String> _exchangeCodeForToken(String code, ProfileProvider profileProvider) async {
    final url = Uri.parse('https://accounts.spotify.com/api/token');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic ' + base64Encode(utf8.encode('${profileProvider.clientId}:${profileProvider.clientSecret}')),
      },
      body: {
        'code': code,
        'redirect_uri': profileProvider.redirectUri,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Erro ao trocar código por token');
    }
  }

  // Busca as playlists do Spotify
  Future<void> _fetchPlaylists(String accessToken) async {
    final url = Uri.parse("https://api.spotify.com/v1/me/playlists");

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _playlists = data['items'];
        });
      } else {
        _showErrorSnackbar("Erro ao buscar playlists: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackbar("Erro ao buscar playlists: $e");
    }
  }

  // Busca as músicas de uma playlist específica
  Future<void> _fetchPlaylistTracks(String playlistId, String accessToken) async {
    final url = Uri.parse("https://api.spotify.com/v1/playlists/$playlistId/tracks");

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tracks = data['items'];
        });
      } else {
        _showErrorSnackbar("Erro ao buscar músicas: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackbar("Erro ao buscar músicas: $e");
    }
  }

  // Exibe a mensagem de erro
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
        title: const Text('Spotify Playlists'),
      ),
      backgroundColor: const Color(0xFF6A1B9A), // Tela roxa
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isAuthenticated
              ? _tracks.isEmpty
                  ? ListView.builder(
                      itemCount: _playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = _playlists[index];
                        return ListTile(
                          leading: playlist['images'] != null && playlist['images'].isNotEmpty
                              ? Image.network(
                                  playlist['images'][0]['url'],
                                  width: 80, // Tamanho aumentado
                                  height: 80, // Tamanho aumentado
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.music_note, size: 80), // Ícone maior
                          title: Text(
                            playlist['name'] ?? 'Sem nome',
                            style: const TextStyle(color: Colors.white, fontSize: 18), // Nome visível
                          ),
                          subtitle: Text(
                            '${playlist['tracks']['total']} músicas',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onTap: () async {
                            final playlistId = playlist['id']; // Pega o ID da playlist
                            final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                            final accessToken = profileProvider.accessToken;

                            if (accessToken != null) {
                              // Carrega as músicas da playlist
                              await _fetchPlaylistTracks(playlistId, accessToken);
                            }
                          },
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: _tracks.length,
                      itemBuilder: (context, index) {
                        final track = _tracks[index];
                        return ListTile(
                          title: Text(
                            track['track']['name'], // Nome da música
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            track['track']['artists'][0]['name'], // Nome do artista
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onTap: () {
                            // Lógica para reproduzir a música ou exibir mais informações
                          },
                        );
                      },
                    )
              : Center(
                  child: ElevatedButton(
                    onPressed: _authenticateSpotify,
                    child: const Text('Login com Spotify'),
                  ),
                ),
    );
  }
}

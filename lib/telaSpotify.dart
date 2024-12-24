import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'profile_provider.dart'; // Import the ProfileProvider
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
  InAppWebViewController? _webViewController;
  late AppLinks appLinks;
  Map<String, dynamic>? _currentlyPlayingTrack;
  String? _selectedPlaylistId; // Armazena o ID da playlist selecionada

  @override
  void initState() {
    super.initState();
    appLinks = AppLinks();
    _initializeSpotify();
    _listenForRedirect();
  }

  Future<void> _initializeSpotify() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final storedToken = profileProvider.accessToken;

      if (storedToken != null && !_isAuthenticated) {
        setState(() {
          _isAuthenticated = true;
        });
        await _initializeSpotifyWebPlayback(storedToken);
        await _fetchPlaylists(storedToken);
        await _fetchCurrentlyPlayingTrack(storedToken);
      } else if (!_isAuthAttempted) {
        await _authenticateSpotify();
      }
    } catch (e) {
      debugPrint("Initialization Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
          'scope': 'playlist-read-private playlist-read-collaborative user-read-playback-state user-modify-playback-state',
        },
      );

      await _launchURLInWebView(authorizationUrl.toString());
    } catch (e) {
      debugPrint("Authentication Error: $e");
    }
  }

  Future<void> _launchURLInWebView(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceWebView: true, enableJavaScript: true);
    } else {
      throw 'Unable to launch URL: $url';
    }
  }

  Future<void> _listenForRedirect() async {
    appLinks.uriLinkStream.listen((Uri? uri) async {
      if (uri != null && uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code']!;
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

        final accessToken = await _exchangeCodeForToken(code, profileProvider);

        if (accessToken.isNotEmpty) {
          profileProvider.setAccessToken(accessToken);
          setState(() {
            _isAuthenticated = true;
          });
          await _initializeSpotifyWebPlayback(accessToken);
          await _fetchPlaylists(accessToken);
          await _fetchCurrentlyPlayingTrack(accessToken);
        }
      }
    });
  }

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
      throw Exception('Error exchanging code for token');
    }
  }

  Future<void> _initializeSpotifyWebPlayback(String accessToken) async {
    final scriptUrl = 'https://sdk.scdn.co/spotify-player.js';
    final script = '''
      var player;
      window.onSpotifyWebPlaybackSDKReady = () => {
        player = new Spotify.Player({
          name: 'TrackConnections Player',
          getOAuthToken: cb => { cb('$accessToken'); },
          volume: 0.5
        });

        player.addListener('initialization_error', ({ message }) => { console.error(message); });
        player.addListener('authentication_error', ({ message }) => { console.error(message); });
        player.addListener('account_error', ({ message }) => { console.error(message); });
        player.addListener('playback_error', ({ message }) => { console.error(message); });

        player.addListener('player_state_changed', state => {
          if (!state) return;
          const { track_window: { current_track } } = state;
          console.log('Currently playing', current_track.name);
        });

        player.connect();
      };
      const scriptTag = document.createElement('script');
      scriptTag.src = '$scriptUrl';
      document.head.appendChild(scriptTag);
    ''';

    await _webViewController?.evaluateJavascript(source: script);
  }

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
      }
    } catch (e) {
      debugPrint("Error fetching playlists: $e");
    }
  }

  Future<void> _fetchCurrentlyPlayingTrack(String accessToken) async {
    final url = Uri.parse("https://api.spotify.com/v1/me/player/currently-playing");

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty) {
          setState(() {
            _currentlyPlayingTrack = data['item'];
          });

          final trackName = _currentlyPlayingTrack!['name'];
          final artistName = _currentlyPlayingTrack!['artists'][0]['name'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Now playing: $trackName by $artistName'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching currently playing track: $e");
    }
  }

  // Função para buscar as faixas da playlist
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
          _tracks = data['items']; // Atualiza a lista de faixas
          _selectedPlaylistId = playlistId; // Atualiza a playlist selecionada
        });
      }
    } catch (e) {
      debugPrint("Error fetching playlist tracks: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A1B9A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isAuthenticated
              ? Column(
                  children: [
                    _currentlyPlayingTrack != null
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Now Playing:',
                                  style: TextStyle(color: Colors.white, fontSize: 18),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _currentlyPlayingTrack!['name'],
                                  style: TextStyle(color: Colors.white, fontSize: 24),
                                ),
                                Text(
                                  _currentlyPlayingTrack!['artists'][0]['name'],
                                  style: TextStyle(color: Colors.white70, fontSize: 18),
                                ),
                                _currentlyPlayingTrack!['album']['images'] != null
                                    ? Image.network(
                                        _currentlyPlayingTrack!['album']['images'][0]['url'],
                                        height: 250,
                                        width: 250,
                                      )
                                    : Container(),
                              ],
                            ),
                          )
                        : Container(),
                    if (_selectedPlaylistId == null) // Só exibe a lista de playlists se nenhuma playlist foi selecionada
                      Expanded(
                        child: ListView.builder(
                          itemCount: _playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = _playlists[index];
                            return ListTile(
                              title: Text(playlist['name']),
                              subtitle: Text('Tracks: ${playlist['tracks']['total']}'),
                              leading: playlist['images'].isNotEmpty
                                  ? Image.network(
                                      playlist['images'][0]['url'],
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              onTap: () {
                                final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                                _fetchPlaylistTracks(playlist['id'], profileProvider.accessToken!);
                              },
                            );
                          },
                        ),
                      ),
                    if (_selectedPlaylistId != null)
                      Expanded(
                        child: ListView.builder(
                          itemCount: _tracks.isEmpty ? 1 : _tracks.length, // Exibe mensagem se não houver faixas
                          itemBuilder: (context, index) {
                            if (_tracks.isEmpty) {
                              return Center(
                                child: Text(
                                  'Não há músicas na playlist selecionada',
                                  style: TextStyle(color: Colors.white, fontSize: 18),
                                ),
                              );
                            } else {
                              return ListTile(
                                title: Text(_tracks[index]['track']['name']),
                                subtitle: Text(_tracks[index]['track']['artists'][0]['name']),
                                onTap: () {
                                  // Aqui você pode adicionar a funcionalidade para reproduzir a música ao clicar
                                },
                                leading: Image.network(
                                  _tracks[index]['track']['album']['images'][0]['url'],
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                )
              : Center(
                  child: ElevatedButton(
                    onPressed: _authenticateSpotify,
                    child: const Text('Login with Spotify'),
                  ),
                ),
    );
  }
}

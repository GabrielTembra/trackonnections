import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_provider.dart'; 

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
  late AppLinks appLinks;
  Map<String, dynamic>? _currentlyPlayingTrack;
  String? _selectedPlaylistId;

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

      if (await canLaunch(authorizationUrl.toString())) {
        await launch(authorizationUrl.toString(), forceWebView: true, enableJavaScript: true);
      } else {
        throw 'Unable to launch URL: ${authorizationUrl.toString()}';
      }
    } catch (e) {
      debugPrint("Authentication Error: $e");
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
        }
      }
    } catch (e) {
      debugPrint("Error fetching currently playing track: $e");
    }
  }

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
          _selectedPlaylistId = playlistId;
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
                    if (_currentlyPlayingTrack != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Exibe a imagem da música tocando
                            if (_currentlyPlayingTrack!['album']['images'].isNotEmpty)
                              Image.network(
                                _currentlyPlayingTrack!['album']['images'][0]['url'],
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                            const SizedBox(height: 10),
                            Text(
                              'Now Playing: ${_currentlyPlayingTrack!['name']}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _selectedPlaylistId == null
                          ? ListView.builder(
                              itemCount: _playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = _playlists[index];
                                return ListTile(
                                  leading: playlist['images'].isNotEmpty
                                      ? Image.network(
                                          playlist['images'][0]['url'],
                                          height: 50,
                                          width: 50,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.music_note, size: 50, color: Colors.white),
                                  title: Text(playlist['name'], style: const TextStyle(color: Colors.white)),
                                  onTap: () {
                                    _fetchPlaylistTracks(
                                      playlist['id'],
                                      Provider.of<ProfileProvider>(context, listen: false).accessToken!,
                                    );
                                  },
                                );
                              },
                            )
                          : ListView.builder(
                              itemCount: _tracks.length,
                              itemBuilder: (context, index) {
                                final track = _tracks[index]['track'];
                                return ListTile(
                                  leading: track['album']['images'].isNotEmpty
                                      ? Image.network(
                                          track['album']['images'][0]['url'],
                                          height: 50,
                                          width: 50,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.music_note, size: 50, color: Colors.white),
                                  title: Text(track['name'], style: const TextStyle(color: Colors.white)),
                                );
                              },
                            ),
                    ),
                  ],
                )
              : Center(
                  child: ElevatedButton(
                    onPressed: _authenticateSpotify,
                    child: const Text('Entrar com o Spotify'),
                  ),
                ),
    );
  }
}

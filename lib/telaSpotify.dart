import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_provider.dart'; // Import the ProfileProvider
import 'package:just_audio/just_audio.dart'; // For audio playback
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
  final AudioPlayer _audioPlayer = AudioPlayer(); // Audio player instance

  String? _currentTrackName; // Track name
  String? _currentTrackArtist; // Track artist

  @override
  void initState() {
    super.initState();
    _initializeSpotify();
    _listenForRedirect();

    // Listener to detect changes in audio player state
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          _currentTrackName = null;
          _currentTrackArtist = null;
        });
      }
    });

    // Listen to playback events
    _audioPlayer.playbackEventStream.listen((event) {
      final currentIndex = _audioPlayer.currentIndex;

      // If the current track index is available, update the track info
      if (currentIndex != null) {
        setState(() {
          // Accessing track metadata
          _currentTrackName = _audioPlayer.audioSource!.sequence[0].tag?.toString() ?? "Unknown Track";
          _currentTrackArtist = _audioPlayer.audioSource!.sequence[0].tag?.toString() ?? "Unknown Artist";
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

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
          'scope': 'playlist-read-private playlist-read-collaborative user-read-playback-state',
        },
      );

      // Lança o URL para autenticação do Spotify
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
    final appLinks = AppLinks();

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

          // Aqui fazemos o pop para voltar à tela anterior após a autenticação
          Navigator.pop(context); // Adiciona isso aqui
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
      }
    } catch (e) {
      debugPrint("Error fetching tracks: $e");
    }
  }

  Future<void> _playTrack(String? trackUrl) async {
    if (trackUrl == null || trackUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview not available for this track.'),
        ),
      );
      return;
    }

    try {
      await _audioPlayer.setUrl(trackUrl);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing track: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error playing track. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xFF6A1B9A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isAuthenticated
              ? Column(
                  children: [
                    Expanded(
                      child: _tracks.isEmpty
                          ? ListView.builder(
                              itemCount: _playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = _playlists[index];
                                return ListTile(
                                  leading: playlist['images'] != null && playlist['images'].isNotEmpty
                                      ? Image.network(
                                          playlist['images'][0]['url'],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.music_note, size: 80),
                                  title: Text(
                                    playlist['name'] ?? 'No name',
                                    style: const TextStyle(color: Colors.white, fontSize: 18),
                                  ),
                                  subtitle: Text(
                                    '${playlist['tracks']['total']} tracks',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  onTap: () async {
                                    final playlistId = playlist['id'];
                                    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                                    final accessToken = profileProvider.accessToken;

                                    if (accessToken != null) {
                                      await _fetchPlaylistTracks(playlistId, accessToken);
                                    }
                                  },
                                );
                              },
                            )
                          : ListView.builder(
                              itemCount: _tracks.length,
                              itemBuilder: (context, index) {
                                final track = _tracks[index]['track'];
                                final trackName = track['name'];
                                final trackArtist = track['artists'][0]['name'];
                                final trackPreviewUrl = track['preview_url'];

                                return ListTile(
                                  leading: track['album']['images'] != null && track['album']['images'].isNotEmpty
                                      ? Image.network(
                                          track['album']['images'][0]['url'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.music_note),
                                  title: Text(
                                    trackName,
                                    style: const TextStyle(color: Colors.white, fontSize: 18),
                                  ),
                                  subtitle: Text(
                                    trackArtist,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  onTap: () => _playTrack(trackPreviewUrl),
                                );
                              },
                            ),
                    ),
                  ],
                )
              : Center(
                  child: ElevatedButton(
                    onPressed: _authenticateSpotify,
                    child: const Text('Authenticate with Spotify'),
                  ),
                ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

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
      home: const YouTubeMusicScreen(),
    );
  }
}

class YouTubeMusicScreen extends StatefulWidget {
  const YouTubeMusicScreen({super.key});

  @override
  _YouTubeMusicScreenState createState() => _YouTubeMusicScreenState();
}

class _YouTubeMusicScreenState extends State<YouTubeMusicScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/youtube.readonly'],
  );
  String? _accessToken;
  List<dynamic> _recentMusicVideos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkGoogleSignIn();
  }

  Future<void> _checkGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    if (await _googleSignIn.isSignedIn()) {
      final auth = await _googleSignIn.currentUser?.authentication;
      _accessToken = auth?.accessToken;
      await _getYouTubeMusicVideos();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signInWithGoogle() async {
    final user = await _googleSignIn.signIn();
    if (user != null) {
      final auth = await user.authentication;
      _accessToken = auth.accessToken;
      // Depois de autenticar, redireciona para o YouTube diretamente
      await _launchYouTube();
      await _getYouTubeMusicVideos();
    }
  }

  Future<void> _getYouTubeMusicVideos() async {
    if (_accessToken != null) {
      setState(() {
        _isLoading = true;
      });
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&videoCategoryId=10&maxResults=10'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _recentMusicVideos = data['items'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao obter vídeos musicais.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para abrir o YouTube
  Future<void> _launchYouTube() async {
    const url = 'https://www.youtube.com';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Não foi possível abrir o YouTube';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Músicas Recentes no YouTube'),
      ),
      body: Column(
        children: [
          if (_accessToken == null)
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: const Text('Login com Google'),
            ),
          if (_isLoading)
            const CircularProgressIndicator(),
          if (_recentMusicVideos.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _recentMusicVideos.length,
                itemBuilder: (context, index) {
                  final video = _recentMusicVideos[index];
                  final snippet = video['snippet'];
                  final title = snippet['title'];
                  final artist = snippet['channelTitle']; // Canal como artista
                  final description = snippet['description'];
                  final videoId = video['id']['videoId']; // Pega o ID correto

                  return ListTile(
                    title: Text(title),
                    subtitle: Text('Artista: $artist\nDescrição: $description'),
                    onTap: () {
                      // Ação para abrir o vídeo no YouTube
                      _launchVideo(videoId);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Função para abrir o vídeo no YouTube
  void _launchVideo(String videoId) async {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Não foi possível abrir o vídeo';
    }
  }
}

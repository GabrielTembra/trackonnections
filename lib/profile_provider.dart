import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotify/spotify.dart';

class ProfileProvider extends ChangeNotifier {
  // Credenciais do Spotify
  final String clientId = 'fce00c0056db400cb5276479df7e6ab7';
  final String clientSecret = 'd009b17417f24a048be9432529b7d026';
  final String redirectUri = 'https://trackonnections.web.app/spotify';

  // Variáveis do perfil
  Uint8List? _profileImageBytes;
  Color _profileColor = const Color(0xFF4A148C);
  String _profileName = '';
  String _profileDescription = '';
  String _profilePlaylist = '';
  String? _spotifyToken;
  String? _accessToken;

  // Variáveis para o estado de gravação
  bool _isRecording = false;
  String? _audioPath;

  // Variáveis de localização
  double _latitude = 0.0;
  double _longitude = 0.0;

  // Variáveis de navegação
  int _currentPageIndex = 0;

  // Variáveis de login do Firebase
  String? _firebaseEmail;
  String? _firebaseAuthToken;

  // Variável de autenticação
  bool _isAuthenticated = false;

  // Variáveis de playlists
  List<dynamic> _playlists = [];
  bool _isLoadingPlaylists = false;

  // Instância do Google Map
  GoogleMapController? _mapController;

  // Variáveis de música
  bool _isMusicPlaying = false;
  String _currentSongName = '';
  String _currentSongArtist = '';
  String _albumArtUrl = '';  // URL da arte do álbum

  // Hotspot Status
  bool _isHotspotActive = false;

  // Getters
  Uint8List? get profileImageBytes => _profileImageBytes;
  Color get profileColor => _profileColor;
  String get profileName => _profileName;
  String get profileDescription => _profileDescription;
  String get profilePlaylist => _profilePlaylist;
  String? get spotifyToken => _spotifyToken;
  String? get accessToken => _accessToken;
  bool get isRecording => _isRecording;
  String? get audioPath => _audioPath;
  double get latitude => _latitude;
  double get longitude => _longitude;
  int get currentPageIndex => _currentPageIndex;
  String? get firebaseEmail => _firebaseEmail;
  String? get firebaseAuthToken => _firebaseAuthToken;
  bool get isAuthenticated => _isAuthenticated;
  bool get isHotspotActive => _isHotspotActive;
  bool get isMusicPlaying => _isMusicPlaying;
  String get currentSongName => _currentSongName;
  String get currentSongArtist => _currentSongArtist;
  String get albumArtUrl => _albumArtUrl;
  List<dynamic> get playlists => _playlists;
  bool get isLoadingPlaylists => _isLoadingPlaylists;
  GoogleMapController? get mapController => _mapController;

  // Método para alternar entre as telas
  void changePage(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  // Função para carregar as playlists do Spotify
  Future<void> fetchPlaylists() async {
    if (_spotifyToken == null) {
      print('Token do Spotify não encontrado.');
      return;
    }

    _isLoadingPlaylists = true;
    notifyListeners();

    final url = Uri.parse('https://api.spotify.com/v1/me/playlists');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_spotifyToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _playlists = data['items']; // Lista de playlists
      _isLoadingPlaylists = false;
    } else {
      print('Erro ao carregar playlists: ${response.statusCode}');
      _isLoadingPlaylists = false;
    }

    notifyListeners();
  }

  // Função para carregar os dados do perfil
  Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _profileImageBytes = base64Decode(prefs.getString('profile_image') ?? '');
    _profileColor = Color(int.parse('0x${prefs.getString('profile_color') ?? 'FF4A148C'}'));
    _profileName = prefs.getString('profile_name') ?? '';
    _profileDescription = prefs.getString('profile_description') ?? '';
    _profilePlaylist = prefs.getString('profile_playlist') ?? '';
    _audioPath = prefs.getString('last_recording_path');
    _spotifyToken = prefs.getString('spotify_token');
    _accessToken = prefs.getString('access_token');
    _latitude = prefs.getDouble('latitude') ?? 0.0;
    _longitude = prefs.getDouble('longitude') ?? 0.0;
    _firebaseEmail = prefs.getString('firebase_email');
    _firebaseAuthToken = prefs.getString('firebase_auth_token');

    // Verificar se a autenticação foi feita
    _isAuthenticated = _firebaseAuthToken != null && _firebaseEmail != null;

    notifyListeners();
  }

  // Função para salvar os dados no Firestore
  Future<void> saveProfileDataToFirestore() async {
    if (!_isAuthenticated) {
      print("User not authenticated. Cannot save data.");
      return; // Não salvar dados se não estiver autenticado
    }
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(_firebaseEmail);

      await userRef.set({
        'profileName': _profileName,
        'profileDescription': _profileDescription,
        'profilePlaylist': _profilePlaylist,
        'profileColor': _profileColor.value.toRadixString(16),
        'profileImage': base64Encode(_profileImageBytes ?? Uint8List(0)),
        'audioPath': _audioPath,
        'spotifyToken': _spotifyToken,
        'accessToken': _accessToken,
        'latitude': _latitude,
        'longitude': _longitude,
        'firebaseEmail': _firebaseEmail,
      }, SetOptions(merge: true));

      print("Profile data saved to Firestore");
    } catch (e) {
      print("Error saving profile data to Firestore: $e");
    }
  }

  // Função para salvar os dados do perfil
  Future<void> saveProfileData({
    String? name,
    String? description,
    String? playlist,
    Color? profileColor,
    Uint8List? profileImageBytes,
    String? audioPath,
    String? spotifyToken,
    String? accessToken,
    double? latitude,
    double? longitude,
    String? firebaseEmail,
    String? firebaseAuthToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (profileImageBytes != null) {
      await prefs.setString('profile_image', base64Encode(profileImageBytes));
    }

    if (profileColor != null) {
      await prefs.setString('profile_color', profileColor.value.toRadixString(16));
    }

    if (name != null) await prefs.setString('profile_name', name);
    if (description != null) await prefs.setString('profile_description', description);
    if (playlist != null) await prefs.setString('profile_playlist', playlist);
    if (audioPath != null) await prefs.setString('last_recording_path', audioPath);
    if (spotifyToken != null) await prefs.setString('spotify_token', spotifyToken);
    if (accessToken != null) await prefs.setString('access_token', accessToken);
    if (latitude != null) await prefs.setDouble('latitude', latitude);
    if (longitude != null) await prefs.setDouble('longitude', longitude);
    if (firebaseEmail != null) await prefs.setString('firebase_email', firebaseEmail);
    if (firebaseAuthToken != null) await prefs.setString('firebase_auth_token', firebaseAuthToken);

    // Atualiza os valores no provider
    _profileImageBytes = profileImageBytes;
    _profileColor = profileColor ?? _profileColor;
    _profileName = name ?? _profileName;
    _profileDescription = description ?? _profileDescription;
    _profilePlaylist = playlist ?? _profilePlaylist;
    _audioPath = audioPath ?? _audioPath;
    _spotifyToken = spotifyToken ?? _spotifyToken;
    _accessToken = accessToken ?? _accessToken;
    _latitude = latitude ?? _latitude;
    _longitude = longitude ?? _longitude;
    _firebaseEmail = firebaseEmail ?? _firebaseEmail;
    _firebaseAuthToken = firebaseAuthToken ?? _firebaseAuthToken;

    // Atualiza o estado de autenticação
    _isAuthenticated = firebaseAuthToken != null && firebaseEmail != null;

    // Chama a função para salvar no Firestore
    saveProfileDataToFirestore();

    notifyListeners();
  }

  // Função para configurar o controlador do mapa
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  // Função para mover a câmera do mapa para a localização atual
  void moveToCurrentLocation(LatLng currentLocation) {
    if (_mapController != null) {
      _mapController!.moveCamera(
        CameraUpdate.newLatLng(
          LatLng(_latitude, _longitude),
        ),
      );
    }
    notifyListeners();
  }

  // Função para definir a música que está tocando
  void setCurrentlyPlayingTrack(String songName, String artistName, Map<String, dynamic> albumData) {
    _currentSongName = songName;
    _currentSongArtist = artistName;
    _albumArtUrl = albumData['images'][0]['url']; // Extrai a URL da arte do álbum
    _isMusicPlaying = true;

    // Notificar listeners sobre a atualização do estado de música
    notifyListeners();
  }

  // Função para definir o Access Token
  void setAccessToken(String token) {
    _accessToken = token;
    notifyListeners();
  }

  // Função para alternar o estado de gravação
  void toggleRecording() {
    _isRecording = !_isRecording;
    notifyListeners();
  }

  // Função para iniciar a gravação
  void startRecording(String audioPath) {
    _isRecording = true;
    _audioPath = audioPath;
    notifyListeners();
  }

  // Função para parar a gravação
  void stopRecording() {
    _isRecording = false;
    notifyListeners();
  }
}

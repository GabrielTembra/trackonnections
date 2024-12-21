import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;  // Para fazer o fetch de playlists
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  List<dynamic> get playlists => _playlists;
  bool get isLoadingPlaylists => _isLoadingPlaylists;

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
      }, SetOptions(merge: true)); // Merge para atualizar dados existentes

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

  // Função para definir o e-mail do Firebase
  void setFirebaseEmail(String email) {
    _firebaseEmail = email;
    saveProfileData(firebaseEmail: email);
    notifyListeners();
  }

  // Função para definir o token de autenticação do Firebase
  void setFirebaseAuthToken(String token) {
    _firebaseAuthToken = token;
    saveProfileData(firebaseAuthToken: token);
    notifyListeners();
  }

  // Função para definir o accessToken
  void setAccessToken(String token) {
    _accessToken = token;
    saveProfileData(accessToken: token);
    notifyListeners();
  }

  // Função para alterar a cor do perfil
  void updateProfileColor(Color newColor) {
    _profileColor = newColor;
    saveProfileData(profileColor: newColor);
    notifyListeners();
  }

  // Função para alterar a imagem do perfil
  void updateProfileImage(Uint8List newImage) {
    _profileImageBytes = newImage;
    saveProfileData(profileImageBytes: newImage);
    notifyListeners();
  }

  // Função para alterar o nome do perfil
  void updateProfileName(String newName) {
    _profileName = newName;
    saveProfileData(name: newName);
    notifyListeners();
  }

  // Função para alterar a descrição do perfil
  void updateProfileDescription(String newDescription) {
    _profileDescription = newDescription;
    saveProfileData(description: newDescription);
    notifyListeners();
  }

  // Função para alterar a playlist
  void updateProfilePlaylist(String newPlaylist) {
    _profilePlaylist = newPlaylist;
    saveProfileData(playlist: newPlaylist);
    notifyListeners();
  }

  // Função para alternar o estado de gravação
  Future<void> toggleRecording() async {
    final prefs = await SharedPreferences.getInstance();

    if (_isRecording) {
      // Pausar gravação
      _isRecording = false;
      notifyListeners();
      // Aqui você pode adicionar a lógica para parar a gravação
      // e salvar o caminho do arquivo de áudio, por exemplo:
      // _audioPath = await stopRecording();
      if (_audioPath != null) {
        await prefs.setString('last_recording_path', _audioPath!);
      }
    } else {
      // Iniciar gravação
      _isRecording = true;
      notifyListeners();
      // Aqui você pode adicionar a lógica para começar a gravação
      // como começar a gravar e salvar o caminho do arquivo
      // _audioPath = await startRecording();
    }
  }
}

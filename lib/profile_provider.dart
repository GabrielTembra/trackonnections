import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';

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
  String? _accessToken; // Adicionando o accessToken

  // Variáveis para o estado de gravação
  bool _isRecording = false;
  String? _audioPath; 

  // Variáveis de localização
  double _latitude = 0.0;
  double _longitude = 0.0;

  // Variáveis de navegação
  int _currentPageIndex = 0; // Para controlar a aba ou página atual
  TabController? _tabController; // Para controlar o TabBar

  // Getters
  Uint8List? get profileImageBytes => _profileImageBytes;
  Color get profileColor => _profileColor;
  String get profileName => _profileName;
  String get profileDescription => _profileDescription;
  String get profilePlaylist => _profilePlaylist;
  String? get spotifyToken => _spotifyToken;
  String? get accessToken => _accessToken; // Getter para accessToken
  bool get isRecording => _isRecording;
  String? get audioPath => _audioPath;
  double get latitude => _latitude;
  double get longitude => _longitude;
  int get currentPageIndex => _currentPageIndex;
  TabController? get tabController => _tabController;

  // Método para alternar entre as telas
  void changePage(int index) {
    _currentPageIndex = index;
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
    _accessToken = prefs.getString('access_token'); // Carregando o accessToken
    _latitude = prefs.getDouble('latitude') ?? 0.0;
    _longitude = prefs.getDouble('longitude') ?? 0.0;

    notifyListeners();
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
    String? accessToken, // Parâmetro para accessToken
    double? latitude,
    double? longitude,
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
    if (accessToken != null) await prefs.setString('access_token', accessToken); // Salvando accessToken
    if (latitude != null) await prefs.setDouble('latitude', latitude);
    if (longitude != null) await prefs.setDouble('longitude', longitude);

    _profileImageBytes = profileImageBytes;
    _profileColor = profileColor ?? _profileColor;
    _profileName = name ?? _profileName;
    _profileDescription = description ?? _profileDescription;
    _profilePlaylist = playlist ?? _profilePlaylist;
    _audioPath = audioPath ?? _audioPath;
    _spotifyToken = spotifyToken ?? _spotifyToken;
    _accessToken = accessToken ?? _accessToken; // Atualizando o accessToken
    _latitude = latitude ?? _latitude;
    _longitude = longitude ?? _longitude;

    notifyListeners();
  }

  // Função para alterar o accessToken
  void setAccessToken(String accessToken) {
    _accessToken = accessToken;
    saveProfileData(accessToken: accessToken); // Salva o accessToken
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

  // Função para alterar a playlist do perfil
  void updateProfilePlaylist(String newPlaylist) {
    _profilePlaylist = newPlaylist;
    saveProfileData(playlist: newPlaylist);
    notifyListeners();
  }

  // Função para iniciar ou parar a gravação
  void toggleRecording() {
    _isRecording = !_isRecording;
    if (!_isRecording) {
      _audioPath = "path/to/recorded/audio/file";
      saveProfileData(audioPath: _audioPath);
    }
    notifyListeners();
  }

  // Função para obter a localização atual do usuário
  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _latitude = position.latitude;
    _longitude = position.longitude;
    saveProfileData(latitude: _latitude, longitude: _longitude);
    notifyListeners();
  }

  // Função para definir o TabController
  void setTabController(TabController tabController) {
    _tabController = tabController;
    notifyListeners();
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class ProfileProvider extends ChangeNotifier {
  // Credenciais do Spotify
  final String clientId = 'fce00c0056db400cb5276479df7e6ab7'; // Substitua pelo seu client_id
  final String clientSecret = 'd009b17417f24a048be9432529b7d026'; // Substitua pelo seu client_secret
  final String redirectUri = 'https://trackonnections.web.app/spotify'; // URL de redirecionamento configurada no Spotify

  // Variáveis do perfil
  Uint8List? _profileImageBytes;
  Color _profileColor = const Color(0xFF4A148C);
  String _profileName = '';
  String _profileDescription = '';
  String _profilePlaylist = '';
  String? _spotifyToken; // Variável para armazenar o token de autenticação do Spotify

  // Variáveis para o estado de gravação
  bool _isRecording = false;
  String? _audioPath; // Caminho do arquivo de áudio

  // Variáveis de localização
  double _latitude = 0.0;
  double _longitude = 0.0;

  // Getters
  Uint8List? get profileImageBytes => _profileImageBytes;
  Color get profileColor => _profileColor;
  String get profileName => _profileName;
  String get profileDescription => _profileDescription;
  String get profilePlaylist => _profilePlaylist;
  String? get spotifyToken => _spotifyToken; // Getter para o token do Spotify
  
  bool get isRecording => _isRecording;
  String? get audioPath => _audioPath;

  double get latitude => _latitude; // Getter para latitude
  double get longitude => _longitude; // Getter para longitude

  // Getter for the access token (Spotify)
  String? get accessToken => _spotifyToken;

  // Método setAccessToken para configurar o accessToken
  void setAccessToken(String token) {
    _spotifyToken = token;
    saveProfileData(spotifyToken: token); // Salvar o token no SharedPreferences
    notifyListeners(); // Notificar a UI
  }

  // Função para carregar os dados do perfil do SharedPreferences
  Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _profileImageBytes = base64Decode(prefs.getString('profile_image') ?? '');
    _profileColor = Color(int.parse('0x${prefs.getString('profile_color') ?? 'FF4A148C'}'));
    _profileName = prefs.getString('profile_name') ?? '';
    _profileDescription = prefs.getString('profile_description') ?? '';
    _profilePlaylist = prefs.getString('profile_playlist') ?? '';
    _audioPath = prefs.getString('last_recording_path'); // Carrega o caminho da última gravação
    _spotifyToken = prefs.getString('spotify_token'); // Carrega o token do Spotify
    
    _latitude = prefs.getDouble('latitude') ?? 0.0; // Carrega a latitude
    _longitude = prefs.getDouble('longitude') ?? 0.0; // Carrega a longitude

    notifyListeners(); // Notifica a UI para atualizar
  }

  // Função para salvar os dados do perfil no SharedPreferences
  Future<void> saveProfileData({
    String? name,
    String? description,
    String? playlist,
    Color? profileColor,
    Uint8List? profileImageBytes,
    String? audioPath,
    String? spotifyToken, // Adicionando o parâmetro de token
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
    if (audioPath != null) await prefs.setString('last_recording_path', audioPath); // Salvar o caminho do áudio

    if (spotifyToken != null) await prefs.setString('spotify_token', spotifyToken); // Salvar o token do Spotify

    if (latitude != null) await prefs.setDouble('latitude', latitude); // Salvar a latitude
    if (longitude != null) await prefs.setDouble('longitude', longitude); // Salvar a longitude

    // Atualiza as variáveis internas e notifica a UI
    _profileImageBytes = profileImageBytes;
    _profileColor = profileColor ?? _profileColor;
    _profileName = name ?? _profileName;
    _profileDescription = description ?? _profileDescription;
    _profilePlaylist = playlist ?? _profilePlaylist;
    _audioPath = audioPath ?? _audioPath;
    _spotifyToken = spotifyToken ?? _spotifyToken; // Atualiza o token do Spotify
    _latitude = latitude ?? _latitude;
    _longitude = longitude ?? _longitude; // Atualiza a localização

    notifyListeners();
  }

  // Função para alterar a cor do perfil
  void updateProfileColor(Color newColor) {
    _profileColor = newColor;
    saveProfileData(profileColor: newColor); // Salvar no SharedPreferences
    notifyListeners();
  }

  // Função para alterar a imagem do perfil
  void updateProfileImage(Uint8List newImage) {
    _profileImageBytes = newImage;
    saveProfileData(profileImageBytes: newImage); // Salvar no SharedPreferences
    notifyListeners();
  }

  // Função para alterar o nome do perfil
  void updateProfileName(String newName) {
    _profileName = newName;
    saveProfileData(name: newName); // Salvar no SharedPreferences
    notifyListeners();
  }

  // Função para alterar a descrição do perfil
  void updateProfileDescription(String newDescription) {
    _profileDescription = newDescription;
    saveProfileData(description: newDescription); // Salvar no SharedPreferences
    notifyListeners();
  }

  // Função para alterar a playlist do perfil
  void updateProfilePlaylist(String newPlaylist) {
    _profilePlaylist = newPlaylist;
    saveProfileData(playlist: newPlaylist); // Salvar no SharedPreferences
    notifyListeners();
  }

  // Função para iniciar ou parar a gravação
  void toggleRecording() {
    _isRecording = !_isRecording;
    if (!_isRecording) {
      // Se a gravação foi parada, salve o áudio (você pode adicionar a lógica para salvar o arquivo)
      _audioPath = "path/to/recorded/audio/file"; // Substitua com o caminho do arquivo gravado
      saveProfileData(audioPath: _audioPath);
    }
    notifyListeners();
  }

  // Função para obter a localização atual do usuário
  Future<void> getCurrentLocation() async {
    // Verifique se as permissões de localização estão concedidas
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Exiba uma mensagem de erro ou lide com o caso onde o serviço de localização está desabilitado
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Exiba uma mensagem de erro ou lide com o caso onde a permissão é negada
        return;
      }
    }

    // Obtenha a posição atual do usuário
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // Atualize a localização e salve no SharedPreferences
    _latitude = position.latitude;
    _longitude = position.longitude;
    saveProfileData(latitude: _latitude, longitude: _longitude);
    
    notifyListeners(); // Notificar a UI para atualizar
  }
}

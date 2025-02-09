import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart'; 
import 'package:trackonnections/telaRecorder.dart';
import 'profile_provider.dart';  

class CustomizeProfileScreen extends StatefulWidget {
  const CustomizeProfileScreen({super.key});

  @override
  _CustomizeProfileScreenState createState() => _CustomizeProfileScreenState();
}

class _CustomizeProfileScreenState extends State<CustomizeProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController playlistController = TextEditingController();
  Uint8List? _profileImageBytes;
  Color _profileColor = const Color(0xFF6A1B9A); // Novo roxo
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioPath;
  String? _userLogin;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final file = uploadInput.files?.first;
      if (file != null) {
        final reader = html.FileReader()..readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _profileImageBytes = reader.result as Uint8List?;
          });
        });
      }
    });
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_profileImageBytes != null) {
      await prefs.setString('profile_image', base64Encode(_profileImageBytes!));
    }
    await prefs.setString('profile_color', _profileColor.value.toRadixString(16));
    await prefs.setString('profile_name', nameController.text);
    await prefs.setString('profile_description', descriptionController.text);
    await prefs.setString('profile_playlist', playlistController.text);

    
    Provider.of<ProfileProvider>(context, listen: false).saveProfileData(
      name: nameController.text,
      description: descriptionController.text,
      playlist: playlistController.text,
      profileColor: _profileColor,
      profileImageBytes: _profileImageBytes,
      audioPath: _audioPath,
    );
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final image = prefs.getString('profile_image');
      if (image != null) _profileImageBytes = base64Decode(image);
      final color = prefs.getString('profile_color');
      if (color != null) _profileColor = Color(int.parse('0x$color'));
      nameController.text = prefs.getString('profile_name') ?? '';
      descriptionController.text = prefs.getString('profile_description') ?? '';
      playlistController.text = prefs.getString('profile_playlist') ?? '';
      _audioPath = prefs.getString('last_recording_path');
      _userLogin = prefs.getString('user_login'); // Carrega o login salvo
    });
  }

  Future<void> _playLastRecording() async {
    final recorderState = Provider.of<RecorderState>(context, listen: false); 
    if (recorderState.filePath != null) {
      await _audioPlayer.play(recorderState.filePath! as Source); 
    }
  }

  void _pickProfileColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha uma cor para o perfil'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _profileColor,
            onColorChanged: (color) => setState(() => _profileColor = color),
            showLabel: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    
   
    await prefs.clear(); 

    
    await prefs.remove('spotify_token'); 
   
    await prefs.remove('user_login'); 

    
    Provider.of<ProfileProvider>(context, listen: false).saveProfileData(
      name: '',
      description: '',
      playlist: '',
      profileColor: const Color(0xFF6A1B9A), 
      profileImageBytes: null,
      audioPath: null,
    );

    // Navega de volta para a tela de login (ou qualquer outra tela desejada)
    Navigator.pushReplacementNamed(context, '/login'); 
  }

  Widget _buildProfileImage() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: SizedBox(
            width: 120,
            height: 120,
            child: _profileImageBytes != null
                ? Image.memory(_profileImageBytes!, fit: BoxFit.cover)
                : const Icon(Icons.person, size: 80, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              decoration: BoxDecoration(
                color: _profileColor,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.camera_alt, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black),
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6A1B9A)), // Novo roxo
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF6A1B9A)), // Novo roxo
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF6A1B9A)), // Novo roxo
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A1B9A), // Novo roxo
      appBar: AppBar(
        backgroundColor: _profileColor, // Novo roxo
        elevation: 0,
        title: const Text('Personalizar Perfil',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(child: _buildProfileImage()),
            const SizedBox(height: 16),
            _buildTextField(controller: nameController, label: 'Nome', icon: Icons.person),
            const SizedBox(height: 16),
            _buildTextField(controller: descriptionController, label: 'Descrição', icon: Icons.description),
            const SizedBox(height: 16),
            _buildTextField(controller: playlistController, label: 'Playlist', icon: Icons.playlist_add),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _pickProfileColor,
                  child: const Text('Escolher Cor'),
                ),
                ElevatedButton(
                  onPressed: _saveProfileData,
                  child: const Text('Salvar Perfil'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _playLastRecording,
              child: const Text('Reproduzir Áudio'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Sair'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            const SizedBox(height: 16),
            // Exibe o login salvo
            Text(
              _userLogin != null ? 'Login: $_userLogin' : 'Usuário não logado',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart'; // Para manipulação no Web
import 'dart:html' as html; // Usar o pacote html para trabalhar com arquivos no Web
import 'dart:typed_data'; // Para converter a imagem em formato de bytes
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Pacote para SharedPreferences
import 'dart:convert'; // Para converter a imagem em base64
import 'package:audioplayers/audioplayers.dart';
import 'package:trackonnections/telaBase.dart'; // Certifique-se de que a HomeScreen está corretamente importada.

class CustomizeProfileScreen extends StatefulWidget {
  const CustomizeProfileScreen({super.key});

  @override
  _CustomizeProfileScreenState createState() => _CustomizeProfileScreenState();
}

class _CustomizeProfileScreenState extends State<CustomizeProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController playlistController = TextEditingController();
  Uint8List? _profileImageBytes; // Variável para armazenar a imagem em formato de bytes
  Color _profileColor = const Color(0xFF4A148C); // Cor inicial para o perfil (mesmo tom da AppBar)
  
  // Player de áudio
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Função para escolher a imagem
  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*'; // Aceitar apenas imagens
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final html.File? file = uploadInput.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _profileImageBytes = reader.result as Uint8List?; // Atualiza a imagem
          });
        });
      }
    });
  }

  // Função para escolher a cor do perfil
  void _pickProfileColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Escolha uma cor para o perfil'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _profileColor,
              onColorChanged: (Color color) {
                setState(() {
                  _profileColor = color; // Atualiza a cor escolhida
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Função para salvar os dados no SharedPreferences
  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    // Convertendo a imagem para base64 e salvando
    if (_profileImageBytes != null) {
      String base64Image = base64Encode(_profileImageBytes!);
      bool imageSaved = await prefs.setString('profile_image', base64Image); // Salva a imagem
      print('Imagem salva: $imageSaved');
    } else {
      print('Nenhuma imagem escolhida.');
    }

    // Salvando a cor de perfil como string hexadecimal
    String colorHex = _profileColor.value.toRadixString(16); // Converte para hex
    bool colorSaved = await prefs.setString('profile_color', colorHex); // Salva a cor
    print('Cor salva: $colorSaved');

    // Salvando nome, descrição e URL da playlist
    bool nameSaved = await prefs.setString('profile_name', nameController.text);
    bool descriptionSaved = await prefs.setString('profile_description', descriptionController.text);
    bool playlistSaved = await prefs.setString('profile_playlist', playlistController.text);

    print('Nome salvo: $nameSaved');
    print('Descrição salva: $descriptionSaved');
    print('Playlist salva: $playlistSaved');
  }

  // Função para carregar os dados do SharedPreferences
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    // Carregar a imagem se existir
    String? base64Image = prefs.getString('profile_image');
    if (base64Image != null) {
      setState(() {
        _profileImageBytes = base64Decode(base64Image); // Carrega a imagem de volta
      });
      print('Imagem carregada.');
    } else {
      print('Nenhuma imagem encontrada.');
    }

    // Carregar a cor de perfil se existir
    String? colorHex = prefs.getString('profile_color');
    if (colorHex != null) {
      setState(() {
        _profileColor = Color(int.parse('0x$colorHex')); // Carrega a cor de volta
      });
      print('Cor carregada.');
    }

    // Carregar nome, descrição e URL da playlist
    String? name = prefs.getString('profile_name');
    String? description = prefs.getString('profile_description');
    String? playlist = prefs.getString('profile_playlist');

    setState(() {
      nameController.text = name ?? '';
      descriptionController.text = description ?? '';
      playlistController.text = playlist ?? '';
    });

    print('Nome carregado: ${name ?? "não encontrado"}');
    print('Descrição carregada: ${description ?? "não encontrada"}');
    print('Playlist carregada: ${playlist ?? "não encontrada"}');
  }

  // Função para reproduzir o áudio
  Future<void> _playLastRecording() async {
    final prefs = await SharedPreferences.getInstance();
    final String? filePath = prefs.getString('last_recording_path');
    
    if (filePath != null) {
      await _audioPlayer.play(filePath as Source);
      print('Reproduzindo: $filePath');
    } else {
      print('Nenhuma gravação encontrada.');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Carrega os dados do perfil
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Desfaz o player quando a tela for destruída
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A148C), // Fundo roxo escuro, mesmo tom da AppBar
      appBar: AppBar(
        backgroundColor: _profileColor, // A cor do AppBar muda para a cor do perfil
        elevation: 0,
        title: const Text(
          'Personalizar Perfil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Roboto',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Volta para a tela anterior
          },
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Definindo a cor do ícone como branco
        ),
        actions: [
          // Ícone de casa no canto superior direito
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              // Redireciona diretamente para a HomeScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()), // Redireciona para a HomeScreen
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Foto de perfil
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 120.0,
                      height: 120.0,
                      child: _profileImageBytes != null
                          ? Image.memory(
                              _profileImageBytes!,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.person,
                              size: 80.0,
                              color: Colors.white,
                            ),
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
                        padding: const EdgeInsets.all(8.0),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            // Nome
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: Colors.black),
                  labelText: 'Nome',
                  labelStyle: const TextStyle(color: Colors.deepPurple),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Roboto'),
              ),
            ),
            const SizedBox(height: 16.0),
            // Descrição
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.description, color: Colors.black),
                  labelText: 'Descrição',
                  labelStyle: const TextStyle(color: Colors.deepPurple),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Roboto'),
              ),
            ),
            const SizedBox(height: 16.0),
            // Playlist
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TextField(
                controller: playlistController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.playlist_add, color: Colors.black),
                  labelText: 'Playlist',
                  labelStyle: const TextStyle(color: Colors.deepPurple),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Roboto'),
              ),
            ),
            const SizedBox(height: 16.0),
            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _pickProfileColor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Fundo branco
                    foregroundColor: const Color(0xFF4A148C), // Texto roxo
                  ),
                  child: const Text('Escolher Cor'),
                ),
                ElevatedButton(
                  onPressed: _saveProfileData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Fundo branco
                    foregroundColor: const Color(0xFF4A148C), // Texto roxo
                  ),
                  child: const Text('Salvar Perfil'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Botão para reproduzir o áudio
            ElevatedButton(
              onPressed: _playLastRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Fundo branco
                foregroundColor: const Color(0xFF4A148C), // Texto roxo
              ),
              child: const Text('Reproduzir Áudio'),
            ),
          ],
        ),
      ),
    );
  }
}

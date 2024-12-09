import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:acr_cloud_sdk/acr_cloud_sdk.dart';  // Importando corretamente o SDK
import 'package:maps_launcher/maps_launcher.dart';
import 'package:latlong2/latlong.dart';  // Para coordenadas

void main() {
  runApp(const TrackConnectionsApp());
}

class TrackConnectionsApp extends StatelessWidget {
  const TrackConnectionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrackConnections',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.deepPurple,
      ),
      home: const MapaScreen(),
    );
  }
}

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  _MapaScreenState createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecording = false;
  String _musicInfo = ''; // Para armazenar o título da música detectada

  final AcrCloudSdk _acrCloud = AcrCloudSdk();  // Instanciando o SDK ACRCloud

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _initialize();
    _acrCloud.init(
      host: 'YOUR_ACRCLOUD_HOST',  // Substitua com o seu host ACRCloud
      accessKey: 'YOUR_ACCESS_KEY',  // Substitua com sua chave de acesso
      accessSecret: 'YOUR_ACCESS_SECRET',  // Substitua com seu segredo de acesso
    );
  }

  Future<void> _initialize() async {
    // Solicitar permissões para o microfone
    await Permission.microphone.request();
  }

  // Iniciar a gravação
  Future<void> _startRecording() async {
    if (await Permission.microphone.isGranted) {
      await _audioRecorder!.startRecorder(toFile: 'audio.wav');
      setState(() {
        _isRecording = true;
      });
    } else {
      // Caso não tenha permissão, pedir permissão
      await Permission.microphone.request();
    }
  }

  // Parar a gravação
  Future<void> _stopRecording() async {
    await _audioRecorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });

    // Aqui você enviaria o arquivo de áudio para a ACRCloud
    _identifyMusic();
  }

  // Função para integrar com ACRCloud
  Future<void> _identifyMusic() async {
    try {
      // Enviar o arquivo de áudio para ACRCloud para reconhecimento
      final result = await _acrCloud.recognizeFromFile('audio.wav'); // Corrigido para usar recognizeFromFile

      // Verificando se a música foi identificada
      final music = result['metadata']?['music']?[0];
      
      if (music != null) {
        setState(() {
          _musicInfo = music['title'] ?? 'Título não encontrado';
        });
      } else {
        setState(() {
          _musicInfo = 'Música não identificada';
        });
      }
    } catch (e) {
      print('Erro ao identificar música: $e');
      setState(() {
        _musicInfo = 'Erro ao identificar música';
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _audioRecorder?.closeAudioSession();  // O método de encerramento pode ser opcional
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Row(
          children: const [
            Icon(Icons.music_note, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'TrackConnections',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Explore locais com música!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12), // Bordas arredondadas para o mapa
                child: GestureDetector(
                  onTap: _openMap, // Ao clicar no mapa, abre o Google Maps
                  child: Container(
                    color: Colors.grey[200], // Cor de fundo para simular um mapa
                    child: Center(
                      child: Icon(
                        Icons.map,
                        color: Colors.deepPurple,
                        size: 80.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Botões de iniciar e parar gravação
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRecording ? null : _startRecording,
                  child: const Text('Iniciar Gravação'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isRecording ? _stopRecording : null,
                  child: const Text('Parar Gravação'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Exibir informações sobre a música detectada
            if (_musicInfo.isNotEmpty)
              Text(
                'Música detectada: $_musicInfo',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Função para abrir o Google Maps
  void _openMap() {
    final LatLng location = LatLng(-23.5505, -46.6333); // São Paulo
    MapsLauncher.launchCoordinates(location.latitude, location.longitude);
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:http/http.dart' as http;

class AudioRecorder extends StatefulWidget {
  const AudioRecorder({required this.onStop, Key? key}) : super(key: key);

  final void Function(String path) onStop;

  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isRecognizing = false;  // Adicionando o estado de reconhecimento
  int _recordDuration = 0;
  Timer? _timer;
  final FlutterSoundRecord _audioRecorder = FlutterSoundRecord();
  String _recognizedMusic = '';
  String _recognizedArtist = '';
  String? _filePath;

  @override
  void initState() {
    _isRecording = false;
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A1B9A), // Cor roxa
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildRecordStopControl(),
                const SizedBox(width: 20),
                _buildPauseResumeControl(),
              ],
            ),
            const SizedBox(height: 40),
            // Exibe mensagem conforme o estado da gravação
            Text(
              _isRecording
                  ? 'Gravando...'
                  : _isPaused
                      ? 'Gravação pausada'
                      : 'Aguardando para gravar...',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white, 
                fontSize: 18),
            ),
            const SizedBox(height: 40),
            if (_recognizedMusic.isNotEmpty) ...<Widget>[
              Text(
                'Música: $_recognizedMusic',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white, 
                  fontSize: 18),
              ),
              Text(
                'Artista: $_recognizedArtist',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white, 
                  fontSize: 18),
              ),
            ],
            if (!_isRecording && !_isPaused && _filePath != null) ...<Widget>[
              ElevatedButton(
                onPressed: _isRecognizing ? null : () => _recognizeMusic(_filePath!), // Desabilita o botão durante o reconhecimento
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A), // Cor roxa para o botão
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Roboto', 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold),
                ),
                child: _isRecognizing
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Enviar para reconhecimento'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (_isRecording || _isPaused) {
      icon = const Icon(Icons.stop, color: Colors.white, size: 40);
      color = Colors.red.withOpacity(0.1);
    } else {
      final ThemeData theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 40);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 80, height: 80, child: icon),
          onTap: () {
            _isRecording ? _stop() : _start();
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl() {
    if (!_isRecording && !_isPaused) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (!_isPaused) {
      icon = const Icon(Icons.pause, color: Colors.white, size: 40);
      color = Colors.red.withOpacity(0.1);
    } else {
      final ThemeData theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow, color: Colors.white, size: 40);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 80, height: 80, child: icon),
          onTap: () {
            _isPaused ? _resume() : _pause();
          },
        ),
      ),
    );
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start();

        bool isRecording = await _audioRecorder.isRecording();
        setState(() {
          _isRecording = isRecording;
          _recordDuration = 0;
        });

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final String? path = await _audioRecorder.stop();

    widget.onStop(path!);
    setState(() {
      _isRecording = false;
      _filePath = path;
    });
  }

  Future<void> _pause() async {
    _timer?.cancel();
    await _audioRecorder.pause();

    setState(() => _isPaused = true);
  }

  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();

    setState(() => _isPaused = false);
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  // Função para reconhecimento de música usando o AudD
  Future<void> _recognizeMusic(String filePath) async {
    setState(() {
      _isRecognizing = true; // Inicia o processo de reconhecimento
    });

    final url = Uri.parse('https://api.audd.io/');
    final request = http.MultipartRequest('POST', url)
      ..fields['api_token'] = '6a40cf17ad250ad3f8e9671ab1dfdd30' // Substitua pela sua chave de API AudD
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (jsonResponse['status'] == 'success') {
        final result = jsonResponse['result'];
        setState(() {
          _recognizedMusic = result['title'] ?? 'Música não reconhecida';
          _recognizedArtist = result['artist'] ?? 'Artista não reconhecido';
        });
      } else {
        setState(() {
          _recognizedMusic = 'Falha ao reconhecer a música';
          _recognizedArtist = '';
        });
      }
    } catch (e) {
      setState(() {
        _recognizedMusic = 'Erro ao enviar o áudio para reconhecimento';
        _recognizedArtist = '';
      });
    } finally {
      setState(() {
        _isRecognizing = false; // Finaliza o processo de reconhecimento
      });
    }
  }
}

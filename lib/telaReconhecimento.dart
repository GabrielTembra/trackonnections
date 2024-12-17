import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioRecorder extends StatefulWidget {
  const AudioRecorder({required this.onStop, Key? key}) : super(key: key);

  final void Function(String path) onStop;

  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordDuration = 0;
  Timer? _timer;
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _audioChunks = [];
  String? _filePath;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRecordingPath();
  }

  // Carregar o caminho da gravação ao iniciar
  Future<void> _loadRecordingPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('last_recording_path');
    setState(() {
      _filePath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A1B9A),
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
            Text(
              _isRecording
                  ? 'Gravando...'
                  : _isPaused
                      ? 'Gravação pausada'
                      : 'Aguardando para gravar...',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 40),
            if (!_isRecording && !_isPaused && _filePath != null) ...<Widget>[
              ElevatedButton(
                onPressed: () => _saveRecordingPath(_filePath!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                child: const Text('Salvar gravação'),
              ),
              const SizedBox(height: 20),
              // Exibir áudio gravado
              if (_filePath != null) 
                Column(
                  children: [
                    const Text(
                      'Áudio gravado:',
                      style: TextStyle(color: Colors.white),
                    ),
                    AudioPlayerWidget(filePath: _filePath!),
                  ],
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
    if (html.window.navigator.mediaDevices != null) {
      try {
        final mediaStream = await html.window.navigator.mediaDevices!
            .getUserMedia({'audio': true}); // Solicita acesso ao microfone
        _mediaRecorder = html.MediaRecorder(mediaStream);
        _audioChunks.clear();

        // Listen to 'dataavailable' event to collect recorded audio data
        _mediaRecorder?.addEventListener('dataavailable', (event) {
          final html.Blob blob = event as html.Blob;
          _audioChunks.add(blob);
        });

        // Listen to 'stop' event to handle when the recording stops
        _mediaRecorder?.addEventListener('stop', (event) {
          final audioBlob = html.Blob(_audioChunks);
          final url = html.Url.createObjectUrlFromBlob(audioBlob);
          setState(() {
            _filePath = url;
          });
          widget.onStop(url);
        });

        _mediaRecorder?.start();
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });
        _startTimer();

        // Limit the recording to 12 seconds
        Future.delayed(const Duration(seconds: 12), () {
          if (_isRecording) {
            _stop(); // Stop recording after 12 seconds
          }
        });
      } catch (e) {
        debugPrint('Erro ao iniciar gravação: $e');
        // Adicionar feedback ao usuário caso o microfone não seja acessado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível acessar o microfone.')),
        );
      }
    } else {
      // Caso o navegador não suporte getUserMedia
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navegador não suporta gravação de áudio.')),
      );
    }
  }

  Future<void> _stop() async {
    _mediaRecorder?.stop();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _pause() async {
    _timer?.cancel();
    _mediaRecorder?.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resume() async {
    _startTimer();
    _mediaRecorder?.resume();
    setState(() => _isPaused = false);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  Future<void> _saveRecordingPath(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_recording_path', filePath);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gravação salva com sucesso!')),
    );
  }
}

class AudioPlayerWidget extends StatelessWidget {
  final String filePath;
  const AudioPlayerWidget({required this.filePath, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.play_arrow, color: Colors.white),
      onPressed: () {
        html.window.open(filePath, 'audio');
      },
    );
  }
}

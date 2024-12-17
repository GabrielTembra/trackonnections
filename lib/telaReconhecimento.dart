import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
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
  final FlutterSoundRecord _audioRecorder = FlutterSoundRecord();
  String? _filePath;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
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

        // Limite a gravação a 12 segundos
        Future.delayed(const Duration(seconds: 12), () {
          if (_isRecording) {
            _stop(); // Para a gravação após 12 segundos
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stop() async {
    final String? path = await _audioRecorder.stop();
    if (path != null) {
      widget.onStop(path);
      setState(() {
        _isRecording = false;
        _filePath = path;
      });

      // Salva o caminho da gravação no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_recording_path', path);
    }
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

  Future<void> _saveRecordingPath(String filePath) async {
    // Salva o caminho no SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_recording_path', filePath);

    // Exibe um feedback para o usuário
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gravação salva com sucesso!')),
    );
  }
}

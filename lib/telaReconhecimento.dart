import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackonnections/telaRecorder.dart';

class AudioRecorder extends StatefulWidget {
  const AudioRecorder({Key? key, required Null Function(String path) onStop}) : super(key: key);

  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  Timer? _timer;
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _audioChunks = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecorderState>(
      builder: (context, recorderState, child) {
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
                    _buildRecordStopControl(recorderState),
                    const SizedBox(width: 20),
                    _buildPauseResumeControl(recorderState),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  recorderState.isRecording
                      ? 'Gravando...'
                      : recorderState.isPaused
                          ? 'Gravação pausada'
                          : 'Aguardando para gravar...',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 40),
                if (!recorderState.isRecording && !recorderState.isPaused && recorderState.filePath != null) ...[
                  ElevatedButton(
                    onPressed: () => _saveRecordingPath(recorderState.filePath!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
                  if (recorderState.filePath != null)
                    Column(
                      children: [
                        const Text(
                          'Áudio gravado:',
                          style: TextStyle(color: Colors.white),
                        ),
                        AudioPlayerWidget(filePath: recorderState.filePath!),
                      ],
                    ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordStopControl(RecorderState recorderState) {
    late Icon icon;
    late Color color;

    if (recorderState.isRecording || recorderState.isPaused) {
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
            recorderState.isRecording ? _stop() : _start(recorderState);
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl(RecorderState recorderState) {
    if (!recorderState.isRecording && !recorderState.isPaused) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (!recorderState.isPaused) {
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
            recorderState.isPaused ? _resume(recorderState) : _pause(recorderState);
          },
        ),
      ),
    );
  }

  Future<void> _start(RecorderState recorderState) async {
    if (html.window.navigator.mediaDevices != null) {
      try {
        final mediaStream = await html.window.navigator.mediaDevices!
            .getUserMedia({'audio': true});
        _mediaRecorder = html.MediaRecorder(mediaStream);
        _audioChunks.clear();

        _mediaRecorder?.addEventListener('dataavailable', (event) {
          final html.Blob blob = event as html.Blob;
          _audioChunks.add(blob);
        });

        _mediaRecorder?.addEventListener('stop', (event) {
          final audioBlob = html.Blob(_audioChunks);
          final url = html.Url.createObjectUrlFromBlob(audioBlob);
          recorderState.stopRecording(url);
        });

        _mediaRecorder?.start();
        recorderState.startRecording();

        Future.delayed(const Duration(seconds: 12), () {
          if (recorderState.isRecording) {
            _stop();
          }
        });
      } catch (e) {
        debugPrint('Erro ao iniciar gravação: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível acessar o microfone.')))
        ;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navegador não suporta gravação de áudio.')),
      );
    }
  }

  Future<void> _stop() async {
    _mediaRecorder?.stop();
  }

  Future<void> _pause(RecorderState recorderState) async {
    _timer?.cancel();
    _mediaRecorder?.pause();
    recorderState.pauseRecording();
  }

  Future<void> _resume(RecorderState recorderState) async {
    _timer?.cancel();
    _mediaRecorder?.resume();
    recorderState.resumeRecording();
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


import 'package:flutter/foundation.dart';

class RecorderState with ChangeNotifier {
  bool _isRecording = false;
  bool _isPaused = false;
  String? _filePath;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get filePath => _filePath;

  void startRecording() {
    _isRecording = true;
    _isPaused = false;
    notifyListeners();
  }

  void stopRecording(String filePath) {
    _isRecording = false;
    _filePath = filePath;
    notifyListeners();
  }

  void pauseRecording() {
    _isPaused = true;
    notifyListeners();
  }

  void resumeRecording() {
    _isPaused = false;
    notifyListeners();
  }

  void setFilePath(String filePath) {
    _filePath = filePath;
    notifyListeners();
  }
}

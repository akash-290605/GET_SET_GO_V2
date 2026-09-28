import 'package:flutter/material.dart';

class WebMediaService {
  static final WebMediaService instance = WebMediaService._internal();
  WebMediaService._internal();

  bool get isSupported => false;
  bool get isCameraActive => false;
  bool get isRecording => false;
  bool get isListening => false;
  String? get lastRecordedUrl => null;

  Future<bool> initCamera() async => false;
  void stopCamera() {}

  Widget buildCameraPreviewWidget({BoxFit fit = BoxFit.cover}) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 48),
          SizedBox(height: 8),
          Text(
            'Camera preview available on Web browser',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<bool> startRecording({void Function(String transcript)? onLiveTranscript}) async => false;
  Future<String?> stopRecording() async => null;

  Future<bool> startSpeechRecognition({
    required void Function(String transcript) onTranscript,
    void Function()? onDone,
  }) async => false;

  void stopSpeechRecognition() {}

  Future<void> speak(String text, {double rate = 1.0, double pitch = 1.0}) async {}
  void stopSpeaking() {}
}

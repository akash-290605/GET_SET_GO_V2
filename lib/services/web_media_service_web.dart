// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class WebMediaService {
  static final WebMediaService instance = WebMediaService._internal();
  WebMediaService._internal() {
    _registerViewFactory();
  }

  static const String _viewTypeId = 'gsg-web-camera-view';
  static bool _viewRegistered = false;

  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _recordedChunks = [];
  String? _lastRecordedBlobUrl;

  html.SpeechRecognition? _speechRecognition;
  bool _isSpeechRecActive = false;

  bool _isCameraActive = false;
  bool _isRecording = false;

  bool get isSupported => true;
  bool get isCameraActive => _isCameraActive;
  bool get isRecording => _isRecording;
  bool get isListening => _isSpeechRecActive;
  String? get lastRecordedUrl => _lastRecordedBlobUrl;

  void _registerViewFactory() {
    if (_viewRegistered) return;
    try {
      ui_web.platformViewRegistry.registerViewFactory(_viewTypeId, (int viewId) {
        _videoElement ??= html.VideoElement()
          ..autoplay = true
          ..muted = true
          ..setAttribute('playsinline', 'true')
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.transform = 'scaleX(-1)';
        return _videoElement!;
      });
      _viewRegistered = true;
    } catch (e) {
      debugPrint('Error registering camera view factory: $e');
    }
  }

  Future<bool> initCamera() async {
    try {
      _registerViewFactory();

      if (_mediaStream != null) {
        _isCameraActive = true;
        return true;
      }

      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        debugPrint('MediaDevices not supported in this browser.');
        return false;
      }

      final constraints = {
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': true,
      };

      _mediaStream = await mediaDevices.getUserMedia(constraints);
      _isCameraActive = true;

      if (_videoElement != null) {
        _videoElement!.srcObject = _mediaStream;
        _videoElement!.play();
      }

      return true;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _isCameraActive = false;
      return false;
    }
  }

  void stopCamera() {
    try {
      if (_mediaStream != null) {
        for (final track in _mediaStream!.getTracks()) {
          track.stop();
        }
        _mediaStream = null;
      }
      if (_videoElement != null) {
        _videoElement!.srcObject = null;
      }
      _isCameraActive = false;
    } catch (e) {
      debugPrint('Error stopping camera: $e');
    }
  }

  Widget buildCameraPreviewWidget({BoxFit fit = BoxFit.cover}) {
    if (!_isCameraActive) {
      return Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 48),
            SizedBox(height: 8),
            Text(
              'Camera is turned off',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return const HtmlElementView(viewType: _viewTypeId);
  }

  Future<bool> startRecording({void Function(String transcript)? onLiveTranscript}) async {
    try {
      if (_mediaStream == null) {
        final ok = await initCamera();
        if (!ok) return false;
      }

      _recordedChunks.clear();
      if (_lastRecordedBlobUrl != null) {
        html.Url.revokeObjectUrl(_lastRecordedBlobUrl!);
        _lastRecordedBlobUrl = null;
      }

      // Start MediaRecorder
      if (_mediaStream != null) {
        try {
          _mediaRecorder = html.MediaRecorder(_mediaStream!);
          _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
            final data = (event as dynamic).data;
            if (data != null && data is html.Blob && data.size > 0) {
              _recordedChunks.add(data);
            }
          });
          _mediaRecorder!.start(250);
          _isRecording = true;
        } catch (e) {
          debugPrint('MediaRecorder init error: $e');
          _isRecording = true;
        }
      }

      // Start Live Speech Recognition
      if (html.SpeechRecognition.supported) {
        _startSpeechRecognitionInternal(onLiveTranscript);
      }

      return true;
    } catch (e) {
      debugPrint('startRecording error: $e');
      return false;
    }
  }

  void _startSpeechRecognitionInternal(void Function(String transcript)? onLiveTranscript) {
    try {
      _stopSpeechRecognitionInternal();

      _speechRecognition = html.SpeechRecognition()
        ..continuous = true
        ..interimResults = true
        ..lang = 'en-US';

      String accumulatedText = '';

      _speechRecognition!.onResult.listen((event) {
        final results = event.results;
        if (results == null) return;

        final buffer = StringBuffer();
        for (var i = 0; i < results.length; i++) {
          final res = results[i];
          if ((res.length ?? 0) > 0) {
            final alt = res.item(0);
            if (alt.transcript != null) {
              buffer.write(alt.transcript);
              buffer.write(' ');
            }
          }
        }
        accumulatedText = buffer.toString().trim();
        if (onLiveTranscript != null && accumulatedText.isNotEmpty) {
          onLiveTranscript(accumulatedText);
        }
      });

      _speechRecognition!.onError.listen((event) {
        debugPrint('SpeechRecognition error: $event');
      });

      _speechRecognition!.onEnd.listen((event) {
        _isSpeechRecActive = false;
      });

      _speechRecognition!.start();
      _isSpeechRecActive = true;
    } catch (e) {
      debugPrint('Speech recognition start error: $e');
    }
  }

  void _stopSpeechRecognitionInternal() {
    try {
      if (_speechRecognition != null) {
        _speechRecognition!.stop();
        _speechRecognition = null;
      }
      _isSpeechRecActive = false;
    } catch (e) {
      debugPrint('Speech recognition stop error: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      _stopSpeechRecognitionInternal();

      if (_mediaRecorder != null && _isRecording) {
        final completer = Completer<String?>();
        _mediaRecorder!.addEventListener('stop', (event) {
          if (_recordedChunks.isNotEmpty) {
            final blob = html.Blob(_recordedChunks, 'video/webm');
            _lastRecordedBlobUrl = html.Url.createObjectUrlFromBlob(blob);
            completer.complete(_lastRecordedBlobUrl);
          } else {
            completer.complete(null);
          }
        });
        _mediaRecorder!.stop();
        _isRecording = false;

        return await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
      }
      _isRecording = false;
      return null;
    } catch (e) {
      debugPrint('stopRecording error: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<bool> startSpeechRecognition({
    required void Function(String transcript) onTranscript,
    void Function()? onDone,
  }) async {
    try {
      if (!html.SpeechRecognition.supported) {
        return false;
      }

      _stopSpeechRecognitionInternal();

      _speechRecognition = html.SpeechRecognition()
        ..continuous = true
        ..interimResults = true
        ..lang = 'en-US';

      _speechRecognition!.onResult.listen((event) {
        final results = event.results;
        if (results == null) return;

        final buffer = StringBuffer();
        for (var i = 0; i < results.length; i++) {
          final res = results[i];
          if ((res.length ?? 0) > 0) {
            final alt = res.item(0);
            if (alt.transcript != null) {
              buffer.write(alt.transcript);
              buffer.write(' ');
            }
          }
        }
        final text = buffer.toString().trim();
        if (text.isNotEmpty) {
          onTranscript(text);
        }
      });

      _speechRecognition!.onEnd.listen((event) {
        _isSpeechRecActive = false;
        if (onDone != null) onDone();
      });

      _speechRecognition!.start();
      _isSpeechRecActive = true;
      return true;
    } catch (e) {
      debugPrint('Speech recognition error: $e');
      return false;
    }
  }

  void stopSpeechRecognition() {
    _stopSpeechRecognitionInternal();
  }

  Future<void> speak(String text, {double rate = 1.0, double pitch = 1.0}) async {
    try {
      if (html.window.speechSynthesis == null) return;
      html.window.speechSynthesis!.cancel();

      final utterance = html.SpeechSynthesisUtterance(text)
        ..lang = 'en-US'
        ..rate = rate
        ..pitch = pitch;

      html.window.speechSynthesis!.speak(utterance);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  void stopSpeaking() {
    try {
      html.window.speechSynthesis?.cancel();
    } catch (e) {
      debugPrint('TTS stopSpeaking error: $e');
    }
  }
}

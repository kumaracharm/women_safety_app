import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';

/// Voice service for recording and sharing panic voice alerts
/// User must manually press Send - no auto-sending
class VoiceService {
  VoiceService._internal();

  static final VoiceService instance = VoiceService._internal();

  final Record _record = Record();
  String? _lastRecordingPath;
  bool _isRecording = false;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get the last recording path
  String? get lastRecordingPath => _lastRecordingPath;

  /// Ensure microphone and storage permissions are granted
  Future<bool> _ensurePermissions() async {
    // Microphone permission
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        log('VoiceService: Microphone permission denied');
        return false;
      }
    }

    // Storage permission (for Android 10 and below)
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          log('VoiceService: Storage permission denied (may still work with app-specific storage)');
        }
      }
    }

    return true;
  }

  /// Start recording a voice clip (10-30 seconds recommended)
  Future<bool> startRecording() async {
    if (_isRecording) {
      log('VoiceService: Already recording');
      return false;
    }

    if (!await _ensurePermissions()) {
      return false;
    }

    try {
      // Check encoder support
      final isAacSupported = await _record.isEncoderSupported(AudioEncoder.aacLc);
      final encoder = isAacSupported ? AudioEncoder.aacLc : AudioEncoder.wav;

      // Get app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'panic_${DateTime.now().millisecondsSinceEpoch}.${isAacSupported ? 'm4a' : 'wav'}';
      final path = '${dir.path}/$fileName';

      await _record.start(
        path: path,
        encoder: encoder,
        bitRate: 128000,
        samplingRate: 44100,
      );

      _lastRecordingPath = path;
      _isRecording = true;
      log('VoiceService: Recording started at $path');
      return true;
    } catch (e, st) {
      log('VoiceService: Failed to start recording: $e', stackTrace: st);
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      log('VoiceService: Not currently recording');
      return null;
    }

    try {
      final path = await _record.stop();
      _isRecording = false;
      
      if (path != null && File(path).existsSync()) {
        _lastRecordingPath = path;
        log('VoiceService: Recording stopped. File: $path');
        return path;
      } else {
        log('VoiceService: Recording stopped but file not found');
        return null;
      }
    } catch (e, st) {
      log('VoiceService: Failed to stop recording: $e', stackTrace: st);
      _isRecording = false;
      return null;
    }
  }

  /// Share the last recorded file using system share sheet
  /// User must manually press Send - no auto-sending
  Future<void> shareLastRecording({String? text}) async {
    final path = _lastRecordingPath;
    if (path == null || !File(path).existsSync()) {
      log('VoiceService: No recording available to share');
      return;
    }

    await shareRecordingPath(path, text: text);
  }

  /// Share a specific recording file path
  /// User must manually press Send - no auto-sending
  Future<void> shareRecordingPath(String path, {String? text}) async {
    if (!File(path).existsSync()) {
      log('VoiceService: File does not exist: $path');
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(path)],
        text: text ?? 'Emergency voice message from Safety Shield Pro',
        subject: 'Emergency Voice Alert',
      );
      log('VoiceService: Share sheet opened for $path');
    } catch (e, st) {
      log('VoiceService: Failed to share recording: $e', stackTrace: st);
    }
  }

  /// Cancel current recording if active
  Future<void> cancelRecording() async {
    if (_isRecording) {
      try {
        await _record.stop();
        _isRecording = false;
        log('VoiceService: Recording cancelled');
      } catch (e, st) {
        log('VoiceService: Error cancelling recording: $e', stackTrace: st);
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _record.dispose();
  }
}

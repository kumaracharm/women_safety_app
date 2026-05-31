import 'dart:developer';
import 'package:shake/shake.dart';

/// Shake detection service for emergency trigger via device vibration gesture
class ShakeService {
  ShakeService({required this.onShakeDetected});

  final VoidCallback onShakeDetected;
  ShakeDetector? _shakeDetector;

  /// Initialize shake listener
  void initialize() {
    try {
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: (ShakeEvent event) {
          _handleShakeEvent(event);
        },
        shakeThresholdGravity: 2.7,
        shakeSlopTimeMS: 500,
        shakeCountResetTime: 3000,
        minimumShakeCount: 2,
      );
      log('ShakeService: Shake detector initialized and listening');
    } catch (e, st) {
      log('ShakeService: Failed to initialize shake detector: $e', stackTrace: st);
    }
  }

  /// Internal handler for shake events
  void _handleShakeEvent(ShakeEvent event) {
    log('ShakeService: Violent shake pattern detected - triggering emergency');
    onShakeDetected();
  }

  /// Stop listening and cleanup
  void dispose() {
    try {
      _shakeDetector?.stopListening();
      log('ShakeService: Shake detector stopped and disposed');
    } catch (e, st) {
      log('ShakeService: Error disposing shake detector: $e', stackTrace: st);
    }
  }
}

typedef VoidCallback = void Function();
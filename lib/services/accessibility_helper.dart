import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'accessibility_bridge.dart';

enum HapticPattern {
  timeToGetOff('Time to Get Off', [200, 100, 200]),
  needToChangeLines('Line Transfer Notice', [500]),
  serviceDisrupted('Disruption Alert', [100, 50, 100, 50, 300]);

  final String label;
  final List<int> milliseconds;
  const HapticPattern(this.label, this.milliseconds);
}

class AccessibilityHelper {
  /// Reads out AI-personalized status using browser Web Speech API
  static void speakText(String text) {
    if (kIsWeb) {
      try {
        speakJS(text);
        debugPrint('[TTS] Speaking: $text');
        return;
      } catch (e) {
        debugPrint('[TTS Error]: $e');
      }
    }
    debugPrint('[TTS Fallback]: $text');
  }

  /// Triggers one of 3 distinct vibration patterns via navigator.vibrate
  static void triggerHaptic(HapticPattern pattern) {
    if (kIsWeb) {
      try {
        vibrateJS(pattern.milliseconds);
        debugPrint('[Haptic] Triggered pattern: ${pattern.label}');
        return;
      } catch (e) {
        debugPrint('[Haptic Web Error]: $e');
      }
    }
    // Mobile / native fallback
    HapticFeedback.heavyImpact();
  }
}

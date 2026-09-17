import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@JS('accessibilityBridge.speak')
external void _speakJS(String text);

@JS('accessibilityBridge.vibrate')
external void _vibrateJS(JSAny pattern);

@JS('JSON.parse')
external JSAny _jsonParse(String json);

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
        _speakJS(text);
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
        final jsonStr = jsonEncode(pattern.milliseconds);
        _vibrateJS(_jsonParse(jsonStr));
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

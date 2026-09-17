import 'dart:convert';
import 'dart:js_interop';

@JS('accessibilityBridge.speak')
external void _speakJS(String text);

@JS('accessibilityBridge.vibrate')
external void _vibrateJS(JSAny pattern);

@JS('JSON.parse')
external JSAny _jsonParse(String json);

void speakJS(String text) {
  _speakJS(text);
}

void vibrateJS(List<int> pattern) {
  final jsonStr = jsonEncode(pattern);
  _vibrateJS(_jsonParse(jsonStr));
}

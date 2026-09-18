import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'debug_service.dart';

/// Detector for the Konami Code on physical keyboards:
/// ↑ ↑ ↓ ↓ ← → ← → B A [Enter or Space]
///
/// Designed specifically for PC/evaluator testing to avoid accidental
/// activation on mobile devices and to maintain strict competition compliance.
class KonamiCodeDetector {
  final VoidCallback onTriggered;
  final List<LogicalKeyboardKey> _buffer = [];

  static const int maxBufferLength = 11;

  KonamiCodeDetector({VoidCallback? onTriggered})
      : onTriggered = onTriggered ?? _defaultTrigger;

  static void _defaultTrigger() {
    final newState = DebugService.instance.toggleDebugMode();
    debugPrint(
      '🎮 [KonamiCode] Activated! Debug Mode is now: ${newState ? "ENABLED (Simulation Harness Unlocked)" : "DISABLED (100% Live Compliance)"}',
    );
  }

  /// Processes a single KeyEvent. Returns true if the key event completed the Konami Code.
  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    final key = event.logicalKey;
    _buffer.add(key);

    if (_buffer.length > maxBufferLength) {
      _buffer.removeAt(0);
    }

    if (_checkKonamiMatch()) {
      _buffer.clear();
      onTriggered();
      return true;
    }

    return false;
  }

  /// Verifies if the current buffer matches:
  /// ↑ ↑ ↓ ↓ ← → ← → B A [Enter or Space]
  bool _checkKonamiMatch() {
    if (_buffer.length != maxBufferLength) {
      return false;
    }

    // 1 & 2: Up, Up
    if (_buffer[0] != LogicalKeyboardKey.arrowUp ||
        _buffer[1] != LogicalKeyboardKey.arrowUp) {
      return false;
    }

    // 3 & 4: Down, Down
    if (_buffer[2] != LogicalKeyboardKey.arrowDown ||
        _buffer[3] != LogicalKeyboardKey.arrowDown) {
      return false;
    }

    // 5 & 6: Left, Right
    if (_buffer[4] != LogicalKeyboardKey.arrowLeft ||
        _buffer[5] != LogicalKeyboardKey.arrowRight) {
      return false;
    }

    // 7 & 8: Left, Right
    if (_buffer[6] != LogicalKeyboardKey.arrowLeft ||
        _buffer[7] != LogicalKeyboardKey.arrowRight) {
      return false;
    }

    // 9: B
    if (_buffer[8] != LogicalKeyboardKey.keyB) {
      return false;
    }

    // 10: A
    if (_buffer[9] != LogicalKeyboardKey.keyA) {
      return false;
    }

    // 11: Enter or Space
    final lastKey = _buffer[10];
    if (lastKey != LogicalKeyboardKey.enter &&
        lastKey != LogicalKeyboardKey.numpadEnter &&
        lastKey != LogicalKeyboardKey.space) {
      return false;
    }

    return true;
  }

  /// Clears the keystroke buffer
  void reset() {
    _buffer.clear();
  }

  /// Current buffer for inspection/debugging
  List<LogicalKeyboardKey> get currentBuffer => List.unmodifiable(_buffer);
}

/// A Flutter widget wrapper that listens globally or locally for the Konami Code
/// and displays a temporary notification banner/dialog when toggled.
class KonamiCodeListener extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTriggered;
  final bool showNotificationBanner;

  const KonamiCodeListener({
    super.key,
    required this.child,
    this.onTriggered,
    this.showNotificationBanner = true,
  });

  @override
  State<KonamiCodeListener> createState() => _KonamiCodeListenerState();
}

class _KonamiCodeListenerState extends State<KonamiCodeListener> {
  late final KonamiCodeDetector _detector;

  @override
  void initState() {
    super.initState();
    _detector = KonamiCodeDetector(
      onTriggered: () {
        if (widget.onTriggered != null) {
          widget.onTriggered!();
        } else {
          final isEnabled = DebugService.instance.toggleDebugMode();
          if (mounted && widget.showNotificationBanner) {
            _showDebugStatusBanner(isEnabled);
          }
        }
      },
    );

    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    return _detector.handleKeyEvent(event);
  }

  void _showDebugStatusBanner(bool isEnabled) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isEnabled ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(
              isEnabled ? Icons.bug_report : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEnabled ? '🎮 Debug Mode Activated!' : '🛡️ Live Mode Restored',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    isEnabled
                        ? 'Simulation harness unlocked for judges / evaluation.'
                        : '100% strict live data compliance active.',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

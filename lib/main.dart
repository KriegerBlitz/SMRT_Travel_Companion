import 'package:flutter/material.dart';
import 'core/debug/konamicode.dart';
import 'features/home/home_screen.dart';
import 'features/landing/landing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SMRTTravelCompanionApp());
}

class SMRTTravelCompanionApp extends StatelessWidget {
  const SMRTTravelCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMRT Travel Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D14),
      ),
      builder: (context, child) {
        // Global Konami Code Keystroke Listener (↑ ↑ ↓ ↓ ← → ← → B A Enter/Space)
        return KonamiCodeListener(
          child: MobileViewportContainer(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const MainNavigationRoot(),
    );
  }
}

/// Root widget managing the transition between the Landing Page and Home Page
class MainNavigationRoot extends StatefulWidget {
  const MainNavigationRoot({super.key});

  @override
  State<MainNavigationRoot> createState() => _MainNavigationRootState();
}

class _MainNavigationRootState extends State<MainNavigationRoot> {
  bool _showingLandingPage = true;

  void _navigateToHome() {
    if (!_showingLandingPage) return;
    setState(() {
      _showingLandingPage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
      child: _showingLandingPage
          ? LandingScreen(
              key: const ValueKey('landing_screen'),
              onTransitionToHome: _navigateToHome,
            )
          : const HomeScreen(
              key: ValueKey('home_screen'),
            ),
    );
  }
}

/// STRICTLY DO NOT TOUCH: The entire app is strictly locked to vertical mobile aspect ratio
/// (max 430px wide) across all desktop and mobile screens. Do not remove or alter this framing.
/// Locks aspect ratio to vertical mobile format on wider desktop screens
/// with ambient matte-dark pillarbox bars on the sides.
class MobileViewportContainer extends StatelessWidget {
  final Widget child;

  const MobileViewportContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If device is already mobile-sized (<= 480px wide), use full viewport
        if (constraints.maxWidth <= 480) {
          return child;
        }

        // On desktop/PC: Center the mobile viewport frame with side bars
        return Container(
          color: const Color(0xFF07090E), // Ambient dark background for side bars
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 430, // Standard modern flagship phone width (e.g. iPhone 15 Pro Max)
                maxHeight: 932,
              ),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 40,
                    spreadRadius: 10,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

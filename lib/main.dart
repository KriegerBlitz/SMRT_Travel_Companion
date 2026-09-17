import 'package:flutter/material.dart';
import 'services/simulator_service.dart';
import 'ui/main_shell.dart';
import 'ui/theme.dart';

void main() {
  runApp(const MRTCompanionApp());
}

class MRTCompanionApp extends StatelessWidget {
  const MRTCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MRT Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.bgDark,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.purplePrimary,
          secondary: AppTheme.coralCTA,
          surface: AppTheme.cardBg,
        ),
        fontFamily: 'Roboto',
      ),
      home: const MRTCompanionHomeScreen(),
    );
  }
}

class MRTCompanionHomeScreen extends StatefulWidget {
  const MRTCompanionHomeScreen({super.key});

  @override
  State<MRTCompanionHomeScreen> createState() => _MRTCompanionHomeScreenState();
}

class _MRTCompanionHomeScreenState extends State<MRTCompanionHomeScreen> {
  final SimulatorService _simulator = SimulatorService();

  @override
  Widget build(BuildContext context) {
    return RedesignShell(simulator: _simulator);
  }
}

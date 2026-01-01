import 'package:flutter/material.dart';

import '../main.dart';
import 'video_player_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await VideoPlayerScreen.preloadController(); // 必須処理
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const splashRed = Color(0xFFEF4444);

    return const Scaffold(
      backgroundColor: splashRed,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_fill, size: 100, color: Colors.white),
            SizedBox(height: 16),
            Text(
              "Loading TUBE+...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

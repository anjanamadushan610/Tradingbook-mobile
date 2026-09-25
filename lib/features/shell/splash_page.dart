import 'package:flutter/material.dart';

/// Shown for the instant between launch and the session check. Matches the
/// native splash so the hand-off is invisible.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/images/splash_logo.png', width: 160),
      ),
    );
  }
}

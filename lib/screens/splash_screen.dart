import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';
import 'choice_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // wait for the splash animation / branding to be visible
    await Future.delayed(const Duration(seconds: 3));

    // Firebase keeps the signed-in session persisted on-device automatically.
    // If currentUser is non-null, this phone number already has a valid
    // session and should skip straight past Login/OTP.
    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null) {
      // Already logged in -> let them pick Meet Up or Order Food again,
      // same as a fresh login would.
      Get.off(() => const ChoiceScreen());
    } else {
      Get.off(() => const LoginScreen());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.baloo2(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Weekend ',
                        style: TextStyle(color: Color(0xFF2B1E1A)),
                      ),
                      TextSpan(
                        text: 'Masti',
                        style: TextStyle(color: Color(0xFFFF6B4A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 110,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4A93B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 56),
                const CircularProgressIndicator(
                  color: Color(0xFFFF6B4A),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

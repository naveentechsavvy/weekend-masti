import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'home_screen.dart';
import 'meetup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'splash_screen.dart';

/// Shown right after successful OTP login.
/// User picks between "Meet Up" (join/create a group nearby)
/// and "Order Food" (goes straight into the existing food-ordering flow).
class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: AppColors.white,
  appBar: AppBar(
    backgroundColor: AppColors.white,
    elevation: 0,
    automaticallyImplyLeading: false,
    actions: [
      PopupMenuButton<String>(
        icon: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        onSelected: (value) async {
          if (value == "logout") {
            await FirebaseAuth.instance.signOut();

            Get.offAll(() => const SplashScreen());
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: "logout",
            child: Row(
              children: [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 10),
                Text("Logout"),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
  body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose an option below to continue',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  children: [
                    _ChoiceCard(
                      icon: Icons.groups_rounded,
                      title: 'Meet Up',
                      subtitle:
                          'Create or join a group nearby — yoga, cricket, coffee chats and more',
                      color: const Color(0xFF6C63FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MeetupScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _ChoiceCard(
                      icon: Icons.restaurant_rounded,
                      title: 'Order Food',
                      subtitle:
                          'Browse restaurants near you and get food delivered fast',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _scale = 0.97),
        onTapUp: (_) => setState(() => _scale = 1),
        onTapCancel: () => setState(() => _scale = 1),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(widget.icon, size: 28, color: widget.color),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                      ),
                    ),
                    Icon(Icons.arrow_forward, size: 16, color: widget.color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('🍔', style: TextStyle(fontSize: 40)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Wekend Masti',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
          ),
          Center(
            child: Text('Version 1.0.0',
                style: TextStyle(color: AppColors.textGrey)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Wekend Masti is a food delivery app bringing your favourite restaurants and weekend cravings straight to your door. Order, track, and enjoy — all in one place.',
              style: TextStyle(color: AppColors.textGrey, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _infoTile(Icons.description_outlined, 'Terms of Service'),
                const Divider(height: 1),
                _infoTile(Icons.privacy_tip_outlined, 'Privacy Policy'),
                const Divider(height: 1),
                _infoTile(Icons.star_outline, 'Rate the App'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Made with ❤️ for great weekends',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title) {
    return Builder(
      builder: (context) => ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coming soon')),
        ),
      ),
    );
  }
}

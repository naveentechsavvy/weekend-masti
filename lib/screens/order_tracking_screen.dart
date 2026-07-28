import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'home_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  int _currentStep = 0;

  final List<Map<String, String>> _steps = [
    {'title': 'Order Placed', 'sub': 'We received your order', 'emoji': '✅'},
    {'title': 'Preparing Food', 'sub': 'Restaurant is preparing', 'emoji': '👨‍🍳'},
    {'title': 'Out for Delivery', 'sub': 'Rider is on the way', 'emoji': '🛵'},
    {'title': 'Delivered!', 'sub': 'Enjoy your meal!', 'emoji': '🎉'},
  ];

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _currentStep = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Tracking'),
        backgroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(_steps[_currentStep]['emoji']!,
                style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            Text(_steps[_currentStep]['title']!,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(_steps[_currentStep]['sub']!,
                style: TextStyle(color: AppColors.textGrey, fontSize: 16)),
            const SizedBox(height: 40),
            // Steps
            ...List.generate(_steps.length, (index) {
              final isDone = index <= _currentStep;
              return Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDone ? AppColors.primary : AppColors.divider,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDone ? Icons.check : Icons.circle,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      if (index < _steps.length - 1)
                        Container(
                          width: 2,
                          height: 30,
                          color: isDone ? AppColors.primary : AppColors.divider,
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Text(_steps[index]['title']!,
                      style: TextStyle(
                          fontWeight: isDone ? FontWeight.w700 : FontWeight.normal,
                          color: isDone ? AppColors.textDark : AppColors.textGrey,
                          fontSize: 16)),
                ],
              );
            }),
            const Spacer(),
            if (_currentStep == _steps.length - 1)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
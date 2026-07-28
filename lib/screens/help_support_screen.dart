import 'package:flutter/material.dart';
import '../utils/colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I track my order?',
      'a': 'Go to My Orders from your profile and tap on the active order to see live status.',
    },
    {
      'q': 'How do I cancel an order?',
      'a': 'Orders can be cancelled within a few minutes of placing them, before the restaurant accepts it. Contact support if you need help after that.',
    },
    {
      'q': 'What payment methods are supported?',
      'a': 'We support Cash on Delivery, UPI, and Credit/Debit cards. You can save these under Payment Methods for faster checkout.',
    },
    {
      'q': 'How do I add or change my delivery address?',
      'a': 'Go to Saved Addresses in your profile to add, edit, or remove delivery addresses.',
    },
    {
      'q': 'My order arrived incorrect or incomplete, what do I do?',
      'a': 'Reach out to us via chat or email below with your order details and we will help sort it out.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ContactButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat with us',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support chat coming soon')),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ContactButton(
                    icon: Icons.email_outlined,
                    label: 'Email us',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('support@wekendmasti.com')),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Frequently Asked Questions',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _faqs
                  .map((faq) => ExpansionTile(
                        title: Text(faq['q']!,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                                fontSize: 14)),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        expandedAlignment: Alignment.topLeft,
                        children: [
                          Text(faq['a']!,
                              style: TextStyle(
                                  color: AppColors.textGrey, fontSize: 13)),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

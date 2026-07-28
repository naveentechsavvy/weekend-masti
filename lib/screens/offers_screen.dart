import 'package:flutter/material.dart';
import '../utils/colors.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  static final List<Map<String, String>> _offers = [
    {
      'code': 'WEKEND50',
      'title': 'Flat ₹50 off',
      'desc': 'On orders above ₹199. Valid on weekends.',
    },
    {
      'code': 'FIRSTORDER',
      'title': '20% off your first order',
      'desc': 'Up to ₹100 off. New users only.',
    },
    {
      'code': 'FREEDEL',
      'title': 'Free delivery',
      'desc': 'On orders above ₹299, no minimum cart restriction.',
    },
    {
      'code': 'COMBO30',
      'title': '30% off on combo meals',
      'desc': 'Applicable on select restaurants only.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offers & Coupons'),
        backgroundColor: AppColors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_offer, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer['title']!,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text(offer['desc']!,
                          style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Coupon ${offer['code']} copied')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(offer['code']!,
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

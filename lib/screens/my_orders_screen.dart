import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/order_service.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = OrderService.ordersStream();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.white,
      ),
      body: stream == null
          ? _emptyState(
              icon: Icons.lock_outline,
              title: 'Please log in',
              subtitle: 'Log in to see your order history',
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _emptyState(
                    icon: Icons.error_outline,
                    title: 'Something went wrong',
                    subtitle: 'Could not load your orders right now',
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _emptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                    subtitle: 'Your placed orders will show up here',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final order = docs[index].data();
                    return _OrderCard(order: order);
                  },
                );
              },
            ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

// FIX: converted from StatelessWidget to StatefulWidget so the relative
// timestamp ("2 min ago") can refresh itself on a timer. A StreamBuilder
// only rebuilds when Firestore pushes new data — without this timer, an
// order placed "Just now" would freeze at whatever text it first showed
// and never progress to "1 min ago", "2 min ago", etc. on its own.
class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Re-render every 30s so the relative time label stays accurate
    // without needing new Firestore data to arrive.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Swiggy/Zomato-style relative time: "Just now" -> "X min ago" ->
  /// "X hr ago" -> "Yesterday" -> falls back to an absolute date once an
  /// order is old enough that a relative label stops being useful.
  String _formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return _formatAbsoluteDate(date);
  }

  String _formatAbsoluteDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]}, $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = (order['items'] as List?) ?? [];
    final itemCount =
        items.fold<int>(0, (sum, i) => sum + ((i['qty'] ?? 1) as int));
    final status = (order['status'] ?? 'placed').toString();

    // Prefer the server-resolved timestamp; fall back to the client-side
    // timestamp saved at order creation time so we never get stuck showing
    // "Just now" if the server value hasn't synced down to this device yet.
    final timestamp = (order['createdAt'] as Timestamp?) ??
        (order['createdAtLocal'] as Timestamp?);
    final dateText =
        timestamp != null ? _formatRelative(timestamp.toDate()) : 'Just now';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order['restaurant'] ?? 'Order',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textDark),
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 4),
          Text(dateText,
              style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const Divider(height: 20),
          Text(
            items
                .map((i) => '${i['name']} x${i['qty'] ?? 1}')
                .join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$itemCount item${itemCount == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              Text('₹${order['grandTotal'] ?? 0}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'delivered':
        color = AppColors.success;
        label = 'Delivered';
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'Cancelled';
        break;
      default:
        color = AppColors.warning;
        label = 'Placed';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

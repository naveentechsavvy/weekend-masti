import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'restaurant_detail_screen.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final items = CartManager.items;
    final total = CartManager.totalPrice;
    final delivery = 30;
    final taxes = (total * 0.05).round();
    final grandTotal = total + delivery + taxes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  Text('Your cart is empty!',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text('Add items from restaurants',
                      style: TextStyle(color: AppColors.textGrey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restaurant name
                        if (items.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.store, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(items[0]['restaurant'] ?? '',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Items
                        ...items.map((item) => Dismissible(
                              key: ValueKey(item['name']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.centerRight,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                return await _confirmRemove(context, item['name']);
                              },
                              onDismissed: (direction) {
                                setState(() =>
                                    CartManager.removeItemCompletely(item['name']));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item['name']} removed from cart'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(item['emoji'],
                                        style: const TextStyle(fontSize: 30)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item['name'],
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textDark)),
                                          Text('₹${item['price']} each',
                                              style: TextStyle(
                                                  color: AppColors.textGrey,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(item['qty'] == 1
                                              ? Icons.delete_outline
                                              : Icons.remove_circle_outline),
                                          color: AppColors.primary,
                                          onPressed: () async {
                                            if (item['qty'] == 1) {
                                              final confirmed = await _confirmRemove(
                                                  context, item['name']);
                                              if (confirmed == true) {
                                                setState(() => CartManager
                                                    .removeItemCompletely(
                                                        item['name']));
                                              }
                                            } else {
                                              setState(() => CartManager
                                                  .removeItem(item['name']));
                                            }
                                          },
                                        ),
                                        Text('${item['qty']}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textDark)),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          color: AppColors.primary,
                                          onPressed: () => setState(() =>
                                              CartManager.addItem(
                                                  item, item['restaurant'])),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '₹${item['price'] * item['qty']}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 12),
                        // Bill summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bill Details',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppColors.textDark)),
                              const SizedBox(height: 12),
                              _billRow('Item Total', '₹$total'),
                              _billRow('Delivery Fee', '₹$delivery'),
                              _billRow('Taxes & Charges', '₹$taxes'),
                              Divider(color: AppColors.divider),
                              _billRow('Grand Total', '₹$grandTotal',
                                  bold: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Proceed to checkout button
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.white,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CheckoutScreen(grandTotal: grandTotal)),
                        );
                      },
                      child: Text('Place Order  •  ₹$grandTotal'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<bool?> _confirmRemove(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove "$name" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: bold ? AppColors.textDark : AppColors.textGrey,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: bold ? AppColors.primary : AppColors.textDark,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }
}

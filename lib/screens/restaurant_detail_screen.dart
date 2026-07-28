import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/colors.dart';
import 'cart_screen.dart';
 
// Simple cart manager
class CartManager {
  static final List<Map<String, dynamic>> items = [];
 
  static void addItem(Map<String, dynamic> item, String restaurantName) {
    final existing = items.indexWhere((i) => i['name'] == item['name']);
    if (existing >= 0) {
      items[existing]['qty'] = (items[existing]['qty'] ?? 1) + 1;
    } else {
      items.add({...item, 'qty': 1, 'restaurant': restaurantName});
    }
  }
 
  static void removeItem(String name) {
    final existing = items.indexWhere((i) => i['name'] == name);
    if (existing >= 0) {
      if ((items[existing]['qty'] ?? 1) > 1) {
        items[existing]['qty'] = items[existing]['qty'] - 1;
      } else {
        items.removeAt(existing);
      }
    }
  }
 
  static void removeItemCompletely(String name) {
    items.removeWhere((i) => i['name'] == name);
  }
 
  static int getQty(String name) {
    final existing = items.indexWhere((i) => i['name'] == name);
    return existing >= 0 ? (items[existing]['qty'] ?? 1) : 0;
  }
 
  static int get totalItems =>
      items.fold(0, (sum, item) => sum + (item['qty'] as int));
 
  static int get totalPrice =>
      items.fold(0, (sum, item) => sum + ((item['price'] as int) * (item['qty'] as int)));
}
 
class RestaurantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});
 
  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}
 
class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  void _showAddedSnackBar(String itemName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemName added to cart'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final items = r['items'] as List;
 
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: r['image'] ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: AppColors.divider),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.divider,
                  child: Icon(Icons.restaurant,
                      size: 60, color: AppColors.textGrey),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['name'] ?? '',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(r['cuisine'] ?? '',
                      style: TextStyle(color: AppColors.textGrey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.white, size: 14),
                            Text(' ${r['rating'] ?? ''}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 16, color: AppColors.textGrey),
                      Text(' ${r['time'] ?? ''}',
                          style: TextStyle(color: AppColors.textGrey)),
                      const SizedBox(width: 12),
                      Icon(Icons.people_outline,
                          size: 16, color: AppColors.textGrey),
                      Text(' ${r['price'] ?? ''}',
                          style: TextStyle(color: AppColors.textGrey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (r['discount'] != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer,
                              color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(r['discount'],
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Menu',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index] as Map<String, dynamic>;
                final qty = CartManager.getQty(item['name']);
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(12),
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
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(item['emoji'] ?? '🍽️',
                              style: const TextStyle(fontSize: 35)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'] ?? '',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark)),
                            Text(item['desc'] ?? '',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textGrey)),
                            const SizedBox(height: 4),
                            Text('₹${item['price']}',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                      qty == 0
                          ? ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  CartManager.addItem(item, r['name']);
                                });
                                _showAddedSnackBar(item['name']);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('ADD'),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    color: AppColors.primary,
                                    onPressed: () => setState(() =>
                                        CartManager.removeItem(item['name'])),
                                    constraints: const BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Text('$qty',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700)),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    color: AppColors.primary,
                                    onPressed: () {
                                      setState(() =>
                                          CartManager.addItem(item, r['name']));
                                      _showAddedSnackBar(item['name']);
                                    },
                                    constraints: const BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                );
              },
              childCount: items.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: CartManager.totalItems > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.white,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CartScreen())),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${CartManager.totalItems} items',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    const Text('View Cart',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text('₹${CartManager.totalPrice}',
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles saving/reading past orders for the logged-in user.
/// Stored at: users/{uid}/orders/{orderId}
class OrderService {
  static CollectionReference<Map<String, dynamic>>? _ordersRef() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('orders');
  }

  /// Saves a placed order. Returns the new order's id.
  /// Throws if the user isn't logged in, so callers can surface a clear error
  /// instead of silently proceeding as if the order succeeded.
  static Future<String> placeOrder({
    required List<Map<String, dynamic>> items,
    required int itemTotal,
    required int delivery,
    required int taxes,
    required int grandTotal,
    required String paymentMethod,
    Map<String, dynamic>? address,
  }) async {
    final ref = _ordersRef();
    if (ref == null) {
      throw Exception('You must be logged in to place an order.');
    }

    final restaurantName =
        items.isNotEmpty ? (items[0]['restaurant'] ?? '') : '';

    final doc = await ref.add({
      'items': items,
      'itemTotal': itemTotal,
      'delivery': delivery,
      'taxes': taxes,
      'grandTotal': grandTotal,
      'paymentMethod': paymentMethod,
      'address': address,
      'restaurant': restaurantName,
      'status': 'placed',
      // serverTimestamp() resolves once the write reaches the server; until
      // then it reads back as null on this device. createdAtLocal is a
      // reliable fallback so the UI never gets stuck showing "Just now".
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtLocal': Timestamp.now(),
    });
    return doc.id;
  }

  /// Live stream of the user's orders, most recent first.
  /// Returns null if no user is logged in.
  static Stream<QuerySnapshot<Map<String, dynamic>>>? ordersStream() {
    final ref = _ordersRef();
    if (ref == null) return null;
    return ref.orderBy('createdAt', descending: true).snapshots();
  }
}

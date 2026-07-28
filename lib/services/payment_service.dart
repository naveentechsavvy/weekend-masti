import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manages saved payment methods (UPI / Cards) for the logged-in user.
/// Stored at: users/{uid}/paymentMethods/{id}
/// NOTE: This is a demo flow — no real card data should ever be stored like
/// this in a production app. Card numbers are masked before saving.
class PaymentService {
  static CollectionReference<Map<String, dynamic>>? _ref() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('paymentMethods');
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>? methodsStream() {
    final ref = _ref();
    if (ref == null) return null;
    return ref.orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> addUpi(String upiId, {bool isDefault = false}) async {
    final ref = _ref();
    if (ref == null) throw Exception('Not logged in');
    if (isDefault) await _clearDefaults();

    await ref.add({
      'type': 'upi',
      'upiId': upiId,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> addCard({
    required String cardNumber,
    required String expiry,
    required String holderName,
    bool isDefault = false,
  }) async {
    final ref = _ref();
    if (ref == null) throw Exception('Not logged in');
    if (isDefault) await _clearDefaults();

    final last4 =
        cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : cardNumber;

    await ref.add({
      'type': 'card',
      'last4': last4,
      'expiry': expiry,
      'holderName': holderName,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteMethod(String id) async {
    final ref = _ref();
    if (ref == null) return;
    await ref.doc(id).delete();
  }

  static Future<void> _clearDefaults() async {
    final ref = _ref();
    if (ref == null) return;
    final snap = await ref.where('isDefault', isEqualTo: true).get();
    for (final doc in snap.docs) {
      await doc.reference.update({'isDefault': false});
    }
  }
}

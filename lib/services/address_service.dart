import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manages saved delivery addresses for the logged-in user.
/// Stored at: users/{uid}/addresses/{addressId}
class AddressService {
  static CollectionReference<Map<String, dynamic>>? _ref() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses');
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>? addressesStream() {
    final ref = _ref();
    if (ref == null) return null;
    return ref.orderBy('createdAt', descending: true).snapshots();
  }

  /// One-off fetch (used by checkout to pick a default address without
  /// keeping a stream subscription alive).
  ///
  /// Tries the local cache first so the UI can render instantly; falls back
  /// to a server read if there's no cache yet (e.g. first-ever launch).
  static Future<List<Map<String, dynamic>>> getAddresses() async {
    final ref = _ref();
    if (ref == null) return [];

    try {
      final cached = await ref
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.cache));
      if (cached.docs.isNotEmpty) {
        return cached.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      }
    } catch (_) {
      // No cache available yet — fall through to a server read.
    }

    final snap = await ref.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  static Future<void> addAddress({
    required String label,
    required String line1,
    required String line2,
    required String city,
    required String pincode,
    required String phone,
    bool isDefault = false,
    double? latitude,
    double? longitude,
  }) async {
    final ref = _ref();
    if (ref == null) throw Exception('Not logged in');

    final batch = FirebaseFirestore.instance.batch();

    if (isDefault) {
      final snap = await ref.where('isDefault', isEqualTo: true).get();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }

    final newDoc = ref.doc();
    batch.set(newDoc, {
      'label': label,
      'line1': line1,
      'line2': line2,
      'city': city,
      'pincode': pincode,
      'phone': phone,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static Future<void> updateAddress(
    String id, {
    required String label,
    required String line1,
    required String line2,
    required String city,
    required String pincode,
    required String phone,
    bool isDefault = false,
    double? latitude,
    double? longitude,
  }) async {
    final ref = _ref();
    if (ref == null) throw Exception('Not logged in');

    final batch = FirebaseFirestore.instance.batch();

    if (isDefault) {
      final snap = await ref.where('isDefault', isEqualTo: true).get();
      for (final doc in snap.docs) {
        if (doc.id == id) continue;
        batch.update(doc.reference, {'isDefault': false});
      }
    }

    batch.update(ref.doc(id), {
      'label': label,
      'line1': line1,
      'line2': line2,
      'city': city,
      'pincode': pincode,
      'phone': phone,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
    });

    await batch.commit();
  }

  static Future<void> deleteAddress(String id) async {
    final ref = _ref();
    if (ref == null) return;
    await ref.doc(id).delete();
  }
}

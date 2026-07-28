import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Manages the user's profile — name, photo, bio, interests — stored at
/// users/{uid}. Phone number always comes straight from FirebaseAuth,
/// not Firestore, since that's the source of truth for auth.
class UserService {
  static DocumentReference<Map<String, dynamic>>? _ref() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>>? userStream() {
    final ref = _ref();
    if (ref == null) return null;
    return ref.snapshots();
  }

  static Future<void> setName(String name) async {
    final ref = _ref();
    if (ref == null) throw Exception('Not logged in');
    await ref.set({'name': name}, SetOptions(merge: true));
  }

  /// Updates bio and/or interests. Pass null for a field to leave it
  /// untouched.
  static Future<void> updateProfile({String? bio, List<String>? interests}) async {
    final ref = _ref();
    if (ref == null) throw Exception('Not logged in');
    final data = <String, dynamic>{};
    if (bio != null) data['bio'] = bio;
    if (interests != null) data['interests'] = interests;
    if (data.isEmpty) return;
    await ref.set(data, SetOptions(merge: true));
  }

  /// Uploads a profile photo to Firebase Storage at
  /// profile_photos/{uid}.jpg and saves the download URL to Firestore.
  /// Returns the download URL.
  static Future<String> uploadProfilePhoto(File imageFile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final storageRef =
        FirebaseStorage.instance.ref().child('profile_photos').child('$uid.jpg');

    await storageRef.putFile(imageFile);
    final url = await storageRef.getDownloadURL();

    final ref = _ref();
    if (ref != null) {
      await ref.set({'photoUrl': url}, SetOptions(merge: true));
    }
    return url;
  }

  /// A user is considered verified if their phone number was confirmed
  /// via Firebase phone-auth OTP at login — no separate flow needed.
  static bool isPhoneVerified() {
    return FirebaseAuth.instance.currentUser?.phoneNumber != null;
  }
}

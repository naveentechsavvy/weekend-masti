import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/meetup_group_model.dart';

class LocationPermanentlyDeniedException implements Exception {
  @override
  String toString() =>
      'Location permission permanently denied. Enable it from app settings.';
}

class MeetupService {
  final _db = FirebaseFirestore.instance;
  final _collection = 'meetup_groups';
  final _requestCollection = 'meetup_join_requests';
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationPermanentlyDeniedException();
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
  
  Future<void> requestToJoin({
  required MeetupGroup group,
  required String displayName,
}) async {
  final uid = _uid;

  if (uid == null) {
    throw Exception("Please login");
  }

  // Already a member
  if (group.memberIds.contains(uid)) {
    throw Exception("You are already a member.");
  }

  // Existing pending request
  final existing = await _db
      .collection(_requestCollection)
      .where("groupId", isEqualTo: group.id)
      .where("userId", isEqualTo: uid)
      .where("status", isEqualTo: "pending")
      .get();

  if (existing.docs.isNotEmpty) {
    throw Exception("Join request already sent.");
  }

  await _db.collection(_requestCollection).add({
    "groupId": group.id,
    "groupName": group.name,
    "organizerId": group.createdBy,
    "userId": uid,
    "userName": displayName,
    "status": "pending",
    "requestedAt": FieldValue.serverTimestamp(),
  });
}

Stream<QuerySnapshot<Map<String,dynamic>>> pendingRequests(){

   final uid=_uid;

   return _db
       .collection(_requestCollection)
       .where("organizerId",isEqualTo:uid)
       .where("status",isEqualTo:"pending")
       .snapshots();

}
Future<void> approveRequest({

required String requestId,

}) async{

final requestDoc=await _db
.collection(_requestCollection)
.doc(requestId)
.get();

final data=requestDoc.data();

if(data==null)return;

await joinGroup(
  data["groupId"],
  displayName: data["userName"],
  targetUid: data["userId"],
);

await requestDoc.reference.update({

"status":"approved"

});

}
Future<void> rejectRequest(String requestId) async{

await _db
.collection(_requestCollection)
.doc(requestId)
.update({

"status":"rejected"

});

}
Stream<QuerySnapshot<Map<String,dynamic>>> myPendingRequests(){

final uid=_uid;

return _db
.collection(_requestCollection)
.where("userId",isEqualTo:uid)
.where("status",isEqualTo:"pending")
.snapshots();

}
  double _deg2rad(double deg) => deg * (pi / 180);

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// Creates a new group. Returns the invite code if private, else the doc id.
  Future<String> createGroup({
    required String name,
    required String category,
    required double latitude,
    required double longitude,
    required String creatorName,
    String description = '',
    String eventType = 'instant',
    DateTime? scheduledAt,
    String? imageUrl,
    int maxMembers = 10,
    bool isPrivate = false,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('You must be logged in.');

    if (eventType == 'scheduled' && scheduledAt == null) {
      throw Exception('Please pick a date and time for the event.');
    }
    if (eventType == 'scheduled' && scheduledAt!.isBefore(DateTime.now())) {
      throw Exception('Scheduled time must be in the future.');
    }

    final inviteCode = isPrivate ? _generateInviteCode() : null;
    final checkInCode = _generateInviteCode();

    final group = MeetupGroup(
      id: '',
      name: name,
      category: category,
      description: description,
      createdBy: uid,
      createdByName: creatorName,
      latitude: latitude,
      longitude: longitude,
      memberIds: [uid],
      memberDetails: {uid: creatorName},
      maxMembers: maxMembers,
      status: 'open',
      createdAt: DateTime.now(),
      eventType: eventType,
      scheduledAt: eventType == 'scheduled' ? scheduledAt : null,
      imageUrl: imageUrl,
      isPrivate: isPrivate,
      inviteCode: inviteCode,
      checkInCode: checkInCode,
    );

    final docRef = await _db.collection(_collection).add(group.toMap());
    return isPrivate ? inviteCode! : docRef.id;
  }

  Future<MeetupGroup?> findGroupByInviteCode(String code) async {
    final snap = await _db
        .collection(_collection)
        .where('inviteCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return MeetupGroup.fromDoc(snap.docs.first);
  }

  Future<MeetupGroup?> findGroupByCheckInCode(String code) async {
    final snap = await _db
        .collection(_collection)
        .where('checkInCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return MeetupGroup.fromDoc(snap.docs.first);
  }

  Stream<List<MeetupGroup>> nearbyGroupsStream({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) {
    return _db
        .collection(_collection)
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snapshot) {
      final groups = snapshot.docs.map((d) => MeetupGroup.fromDoc(d)).toList();

      final nearby = groups.where((g) {
        final dist = _distanceKm(latitude, longitude, g.latitude, g.longitude);
        final withinRadius = dist <= radiusKm;
        final notExpired = g.eventType == 'instant' || g.isUpcoming;
        return withinRadius && notExpired && !g.isPrivate;
      }).toList();

      nearby.sort((a, b) {
        if (a.eventType == 'instant' && b.eventType != 'instant') return -1;
        if (a.eventType != 'instant' && b.eventType == 'instant') return 1;

        if (a.eventType == 'instant') {
          final da = _distanceKm(latitude, longitude, a.latitude, a.longitude);
          final db = _distanceKm(latitude, longitude, b.latitude, b.longitude);
          return da.compareTo(db);
        } else {
          return a.scheduledAt!.compareTo(b.scheduledAt!);
        }
      });

      return nearby;
    });
  }

  /// Returns 'joined', 'waitlisted', 'already_joined', or 'already_waitlisted'.
  Future<String> joinGroup(
  String groupId, {
  required String displayName,
  String? targetUid,
}) async {
    final uid = targetUid ?? _uid;
    if (uid == null) throw Exception('You must be logged in.');

    final docRef = _db.collection(_collection).doc(groupId);

    return _db.runTransaction<String>((transaction) async {
      final snapshot = await transaction.get(docRef);
      final group = MeetupGroup.fromDoc(snapshot);

      if (group.memberIds.contains(uid)) return 'already_joined';

      if (!group.isFull) {
        final updatedMembers = [...group.memberIds, uid];
        final updatedDetails = {...group.memberDetails, uid: displayName};
        transaction.update(docRef, {
          'memberIds': updatedMembers,
          'memberDetails': updatedDetails,
          'status': updatedMembers.length >= group.maxMembers ? 'full' : 'open',
        });
        return 'joined';
      } else {
        if (group.waitlistIds.contains(uid)) return 'already_waitlisted';
        final updatedWaitlist = [...group.waitlistIds, uid];
        final updatedWaitlistDetails = {
          ...group.waitlistDetails,
          uid: displayName
        };
        transaction.update(docRef, {
          'waitlistIds': updatedWaitlist,
          'waitlistDetails': updatedWaitlistDetails,
        });
        return 'waitlisted';
      }
    });
  }

  Future<void> leaveGroup(String groupId) async {
    final uid = _uid;
    if (uid == null) return;

    final docRef = _db.collection(_collection).doc(groupId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final group = MeetupGroup.fromDoc(snapshot);

      final updatedMembers =
          group.memberIds.where((id) => id != uid).toList();
      final updatedDetails = {...group.memberDetails}..remove(uid);

      List<String> updatedWaitlist = [...group.waitlistIds];
      Map<String, String> updatedWaitlistDetails = {...group.waitlistDetails};

      if (updatedWaitlist.isNotEmpty &&
          updatedMembers.length < group.maxMembers) {
        final promotedUid = updatedWaitlist.removeAt(0);
        final promotedName = updatedWaitlistDetails.remove(promotedUid);
        updatedMembers.add(promotedUid);
        if (promotedName != null) {
          updatedDetails[promotedUid] = promotedName;
        }
      }

      transaction.update(docRef, {
        'memberIds': updatedMembers,
        'memberDetails': updatedDetails,
        'waitlistIds': updatedWaitlist,
        'waitlistDetails': updatedWaitlistDetails,
        'status': updatedMembers.length >= group.maxMembers ? 'full' : 'open',
      });
    });
  }

  Future<void> leaveWaitlist(String groupId) async {
    final uid = _uid;
    if (uid == null) return;
    final docRef = _db.collection(_collection).doc(groupId);
    await docRef.update({
      'waitlistIds': FieldValue.arrayRemove([uid]),
      'waitlistDetails.$uid': FieldValue.delete(),
    });
  }

  Future<void> deleteGroup(String groupId) async {
    final uid = _uid;
    if (uid == null) throw Exception('You must be logged in.');

    final docRef = _db.collection(_collection).doc(groupId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final group = MeetupGroup.fromDoc(snapshot);
    if (group.createdBy != uid) {
      throw Exception('Only the group creator can cancel this group.');
    }

    await docRef.delete();
  }

  Future<void> removeMember(String groupId, String targetUid) async {
    final uid = _uid;
    if (uid == null) throw Exception('You must be logged in.');

    final docRef = _db.collection(_collection).doc(groupId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final group = MeetupGroup.fromDoc(snapshot);

      if (group.createdBy != uid) {
        throw Exception('Only the group creator can remove members.');
      }
      if (targetUid == group.createdBy) {
        throw Exception('The creator can\'t be removed from their own group.');
      }

      final updatedMembers =
          group.memberIds.where((id) => id != targetUid).toList();
      final updatedDetails = {...group.memberDetails}..remove(targetUid);

      transaction.update(docRef, {
        'memberIds': updatedMembers,
        'memberDetails': updatedDetails,
        'status': 'open',
      });
    });
  }

  /// Returns 'checked_in' or 'already_checked_in'. Throws if not a member.
  Future<String> checkInMember(String groupId) async {
    final uid = _uid;
    if (uid == null) throw Exception('You must be logged in.');

    final docRef = _db.collection(_collection).doc(groupId);

    return _db.runTransaction<String>((transaction) async {
      final snapshot = await transaction.get(docRef);
      final group = MeetupGroup.fromDoc(snapshot);

      if (!group.memberIds.contains(uid)) {
        throw Exception('You must join this group before checking in.');
      }
      if (group.checkedInIds.contains(uid)) {
        return 'already_checked_in';
      }

      transaction.update(docRef, {
        'checkedInIds': [...group.checkedInIds, uid],
      });
      return 'checked_in';
    });
  }
  Stream<bool> isOrganizer() {
  return _db
      .collection(_collection)
      .where("createdBy", isEqualTo: _uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.isNotEmpty);
}

}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_stats_model.dart';

/// Handles points, streaks, and badges earned from meetup activity.
/// Kept as its own service (separate from MeetupService) so meetup logic
/// stays clean — screens call both services after a successful action.
class GamificationService {
  final _db = FirebaseFirestore.instance;
  final _collection = 'user_stats';

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Call this after: creating a group (+20), joining a group (+10),
  /// or checking in at an event (+15). Also updates the daily streak.
  Future<void> awardPoints({
    required int points,
    required String action, // 'create', 'join', 'checkin'
    required String displayName,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final docRef = _db.collection(_collection).doc(uid);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final stats = snapshot.exists
          ? UserStats.fromDoc(snapshot)
          : UserStats.empty(uid, displayName);

      // ---------- STREAK LOGIC ----------
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      int newStreak = stats.streak;

      if (stats.lastActivityDate == null) {
        newStreak = 1;
      } else {
        final last = stats.lastActivityDate!;
        final lastDay = DateTime(last.year, last.month, last.day);
        final daysDiff = today.difference(lastDay).inDays;

        if (daysDiff == 0) {
          // Already active today — streak unchanged.
          newStreak = stats.streak;
        } else if (daysDiff == 1) {
          // Active yesterday, active today — streak continues.
          newStreak = stats.streak + 1;
        } else {
          // Missed a day or more — streak resets.
          newStreak = 1;
        }
      }

      transaction.set(
        docRef,
        {
          'displayName': displayName,
          'points': stats.points + points,
          'streak': newStreak,
          'lastActivityDate': Timestamp.fromDate(now),
          'groupsCreated':
              stats.groupsCreated + (action == 'create' ? 1 : 0),
          'groupsJoined': stats.groupsJoined + (action == 'join' ? 1 : 0),
          'checkIns': stats.checkIns + (action == 'checkin' ? 1 : 0),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Real-time stream of the current user's stats.
  Stream<UserStats?> myStatsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _db.collection(_collection).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserStats.fromDoc(doc);
    });
  }

  /// Real-time leaderboard — top 50 by points, descending.
  Stream<List<UserStats>> leaderboardStream() {
    return _db
        .collection(_collection)
        .orderBy('points', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserStats.fromDoc(d)).toList());
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks a single user's gamification stats across all meetups.
/// Stored in Firestore collection: `user_stats`, document id = user's uid.
class UserStats {
  final String uid;
  final String displayName;
  final int points;
  final int streak; // consecutive days with meetup activity
  final DateTime? lastActivityDate;
  final int groupsCreated;
  final int groupsJoined;
  final int checkIns;

  UserStats({
    required this.uid,
    required this.displayName,
    this.points = 0,
    this.streak = 0,
    this.lastActivityDate,
    this.groupsCreated = 0,
    this.groupsJoined = 0,
    this.checkIns = 0,
  });

  /// Badge tier is derived purely from points — no separate field to keep
  /// in sync, it's always computed fresh from the source of truth.
  String get badgeTier {
    if (points >= 300) return 'Legend';
    if (points >= 150) return 'Champion';
    if (points >= 50) return 'Regular';
    return 'Newbie';
  }

  String get badgeEmoji {
    switch (badgeTier) {
      case 'Legend':
        return '👑';
      case 'Champion':
        return '🏆';
      case 'Regular':
        return '⭐';
      default:
        return '🌱';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'points': points,
      'streak': streak,
      'lastActivityDate': lastActivityDate != null
          ? Timestamp.fromDate(lastActivityDate!)
          : null,
      'groupsCreated': groupsCreated,
      'groupsJoined': groupsJoined,
      'checkIns': checkIns,
    };
  }

  factory UserStats.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserStats(
      uid: doc.id,
      displayName: data['displayName'] ?? 'User',
      points: data['points'] ?? 0,
      streak: data['streak'] ?? 0,
      lastActivityDate: (data['lastActivityDate'] as Timestamp?)?.toDate(),
      groupsCreated: data['groupsCreated'] ?? 0,
      groupsJoined: data['groupsJoined'] ?? 0,
      checkIns: data['checkIns'] ?? 0,
    );
  }

  factory UserStats.empty(String uid, String displayName) {
    return UserStats(uid: uid, displayName: displayName);
  }
}
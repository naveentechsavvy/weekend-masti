import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';
import '../models/user_stats_model.dart';
import '../services/gamification_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = GamificationService();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('Leaderboard',
            style: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      body: StreamBuilder<List<UserStats>>(
        stream: service.leaderboardStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Text('No activity yet — be the first!',
                  style: TextStyle(color: AppColors.textGrey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final stats = list[index];
              final isMe = stats.uid == currentUid;
              final rank = index + 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.primary.withOpacity(0.08)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: isMe
                      ? Border.all(color: AppColors.primary, width: 1.2)
                      : null,
                  boxShadow: isMe
                      ? []
                      : [
                          BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 8,
                              offset: const Offset(0, 2)),
                        ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '$rank',
                        style: TextStyle(
                            fontSize: rank <= 3 ? 18 : 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(stats.badgeEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stats.displayName + (isMe ? ' (You)' : ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark),
                          ),
                          Text(
                            '${stats.badgeTier} • 🔥 ${stats.streak} day streak',
                            style: TextStyle(
                                fontSize: 11.5, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    Text('${stats.points} pts',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontSize: 14)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
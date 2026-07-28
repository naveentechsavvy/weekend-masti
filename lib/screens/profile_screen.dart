import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/colors.dart';
import '../services/user_service.dart';
import '../services/gamification_service.dart';
import '../models/user_stats_model.dart';
import 'login_screen.dart';
import 'my_orders_screen.dart';
import 'saved_addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'offers_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'leaderboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploadingPhoto = false;

  @override
  Widget build(BuildContext context) {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    final userStream = UserService.userStream();
    final isVerified = UserService.isPhoneVerified();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: userStream,
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final name = data?['name'] as String? ?? 'Guest';
                final photoUrl = data?['photoUrl'] as String?;
                final bio = data?['bio'] as String? ?? '';
                final interests =
                    (data?['interests'] as List<dynamic>?)?.cast<String>() ?? [];
                final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

                return Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.15),
                                  backgroundImage:
                                      photoUrl != null ? NetworkImage(photoUrl) : null,
                                  child: photoUrl == null
                                      ? Text(initial,
                                          style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary))
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: _uploadingPhoto
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.camera_alt,
                                            size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textDark)),
                                    ),
                                    if (isVerified) ...[
                                      const SizedBox(width: 6),
                                      Tooltip(
                                        message: 'Verified phone number',
                                        child: Icon(Icons.verified,
                                            size: 18, color: AppColors.primary),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(phone.isNotEmpty ? phone : 'No phone on file',
                                    style: TextStyle(color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: AppColors.primary),
                            onPressed: () =>
                                _editProfile(context, name, bio, interests),
                          ),
                        ],
                      ),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(bio,
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.textDark)),
                        ),
                      ],
                      if (interests.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 8,
                          runSpacing: 8,
                          children: interests
                              .map((tag) => Chip(
                                    label: Text(tag,
                                        style: const TextStyle(fontSize: 12)),
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.1),
                                    labelStyle: TextStyle(color: AppColors.primary),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            // 🏆 Gamification badge strip
            StreamBuilder<UserStats?>(
              stream: GamificationService().myStatsStream(),
              builder: (context, snapshot) {
                final stats = snapshot.data;
                if (stats == null) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                  ),
                  child: Container(
                    color: AppColors.white,
                    margin: const EdgeInsets.only(top: 1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Text(stats.badgeEmoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stats.badgeTier,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark)),
                              Text(
                                  '${stats.points} points • 🔥 ${stats.streak} day streak',
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.textGrey)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 14, color: AppColors.textGrey),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Menu items
            _buildSection([
              _buildTile(
                context,
                Icons.shopping_bag_outlined,
                'My Orders',
                'View past orders',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
              ),
              _buildTile(
                context,
                Icons.location_on_outlined,
                'Saved Addresses',
                'Manage addresses',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SavedAddressesScreen())),
              ),
              _buildTile(
                context,
                Icons.payment_outlined,
                'Payment Methods',
                'Cards & wallets',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())),
              ),
            ]),
            const SizedBox(height: 12),
            _buildSection([
              _buildTile(
                context,
                Icons.local_offer_outlined,
                'Offers & Coupons',
                'View all deals',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OffersScreen())),
              ),
              _buildTile(
                context,
                Icons.help_outline,
                'Help & Support',
                'FAQs and chat',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
              ),
              _buildTile(
                context,
                Icons.info_outline,
                'About',
                'App version 1.0.0',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AboutScreen())),
              ),
            ]),
            const SizedBox(height: 12),
            _buildSection([
              ListTile(
                leading: Icon(Icons.logout, color: AppColors.error),
                title: Text('Logout',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w600)),
                onTap: () => _confirmLogout(context),
              ),
            ]),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      await UserService.uploadProfilePhoto(File(picked.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _editProfile(
      BuildContext context, String currentName, String currentBio, List<String> currentInterests) {
    final nameController = TextEditingController(text: currentName == 'Guest' ? '' : currentName);
    final bioController = TextEditingController(text: currentBio);
    final interestController = TextEditingController();
    final interests = List<String>.from(currentInterests);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                        labelText: 'Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bioController,
                    maxLength: 150,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell people a bit about yourself',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  const Text('Interests',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests
                        .map((tag) => Chip(
                              label: Text(tag),
                              onDeleted: () =>
                                  setSheetState(() => interests.remove(tag)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: interestController,
                    decoration: InputDecoration(
                      hintText: 'Add an interest and press enter',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final v = interestController.text.trim();
                          if (v.isNotEmpty && !interests.contains(v)) {
                            setSheetState(() => interests.add(v));
                            interestController.clear();
                          }
                        },
                      ),
                    ),
                    onSubmitted: (v) {
                      final trimmed = v.trim();
                      if (trimmed.isNotEmpty && !interests.contains(trimmed)) {
                        setSheetState(() => interests.add(trimmed));
                        interestController.clear();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          await UserService.setName(name);
                        }

                        // FIX: if the user typed an interest but never
                        // pressed "+" or Enter, that text was being lost.
                        // Capture it here before saving.
                        final pendingInterest = interestController.text.trim();
                        if (pendingInterest.isNotEmpty &&
                            !interests.contains(pendingInterest)) {
                          interests.add(pendingInterest);
                        }

                        await UserService.updateProfile(
                          bio: bioController.text.trim(),
                          interests: interests,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Save'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (ctx.mounted) {
                Navigator.pushAndRemoveUntil(
                  ctx,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(List<Widget> tiles) {
    return Container(
      color: Colors.white,
      child: Column(children: tiles),
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textGrey),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/colors.dart';
import '../models/meetup_group_model.dart';
import '../services/meetup_service.dart';
import 'home_screen.dart';
import '../services/gamification_service.dart';
import 'leaderboard_screen.dart';
import 'checkin_screen.dart';
import 'group_chat_screen.dart';
import 'direct_chat_screen.dart';
import 'organizer_requests_screen.dart';

class MeetupScreen extends StatefulWidget {
  const MeetupScreen({super.key});

  @override
  State<MeetupScreen> createState() => _MeetupScreenState();
}

class _MeetupScreenState extends State<MeetupScreen> {
  final MeetupService _service = MeetupService();
  final GamificationService _gamification = GamificationService();

  Position? _position;
  bool _loadingLocation = true;
  String? _locationError;
  bool _permanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
      _permanentlyDenied = false;
    });
    try {
      final pos = await _service.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _position = pos;
        _loadingLocation = false;
      });
    } on LocationPermanentlyDeniedException catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString();
        _permanentlyDenied = true;
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString().replaceAll('Exception: ', '');
        _loadingLocation = false;
      });
    }
  }

  Future<void> _openSettingsAndRetry() async {
    await _service.openAppSettings();
  }

  // ---------------- JOIN VIA INVITE CODE ----------------

  void _showJoinViaCodeDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join Private Event'),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Enter 6-character invite code',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              final navigator = Navigator.of(dialogContext);
              try {
                final group = await _service.findGroupByInviteCode(code);
                if (!mounted) return;
                navigator.pop();
                if (group == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid invite code')),
                  );
                  return;
                }
                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                _showMembersSheet(group, currentUid);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(e.toString().replaceAll('Exception: ', ''))),
                );
              }
            },
            child: const Text('Find'),
          ),
        ],
      ),
    );
  }

  // ---------------- CREATE GROUP SHEET ----------------

  void _showCreateGroupSheet() {
    if (_position == null) return;
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();

    String eventType = 'instant';
    DateTime? scheduledDateTime;
    bool isPrivate = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickDateTime() async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: now.add(const Duration(hours: 1)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 90)),
              );
              if (date == null) return;
              if (!context.mounted) return;

              final time = await showTimePicker(
                context: context,
                initialTime:
                    TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
              );
              if (time == null) return;

              setSheetState(() {
                scheduledDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create a group',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    const SizedBox(height: 16),

                    // ---------- INSTANT / SCHEDULED TOGGLE ----------
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() {
                                eventType = 'instant';
                                scheduledDateTime = null;
                              }),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: eventType == 'instant'
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text('Right Now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: eventType == 'instant'
                                          ? Colors.white
                                          : AppColors.textGrey,
                                    )),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setSheetState(() => eventType = 'scheduled'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: eventType == 'scheduled'
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text('Schedule for Later',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: eventType == 'scheduled'
                                          ? Colors.white
                                          : AppColors.textGrey,
                                    )),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (eventType == 'scheduled') ...[
                      GestureDetector(
                        onTap: pickDateTime,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.textLight),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Text(
                                scheduledDateTime == null
                                    ? 'Pick date & time'
                                    : DateFormat('EEE, d MMM • h:mm a')
                                        .format(scheduledDateTime!),
                                style: TextStyle(
                                  color: scheduledDateTime == null
                                      ? AppColors.textGrey
                                      : AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group name (e.g. Sunday Yoga)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText:
                            'What\'s it about? (e.g. Morning yoga, Chess, Trekking)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ---------- PRIVATE TOGGLE ----------
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Private event',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark)),
                              Text('Only people with the invite code can join',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textGrey)),
                            ],
                          ),
                        ),
                        Switch(
                          value: isPrivate,
                          activeColor: AppColors.primary,
                          onChanged: (val) =>
                              setSheetState(() => isPrivate = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) return;
                          if (eventType == 'scheduled' &&
                              scheduledDateTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please pick a date & time')),
                            );
                            return;
                          }

                          final navigator = Navigator.of(context);
                          final rootContext = context;
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            final result = await _service.createGroup(
                              name: nameController.text.trim(),
                              category: categoryController.text.trim().isEmpty
                                  ? 'General'
                                  : categoryController.text.trim(),
                              description: descriptionController.text.trim(),
                              latitude: _position!.latitude,
                              longitude: _position!.longitude,
                              creatorName:
                                  user?.phoneNumber ?? 'A Wekend Masti user',
                              eventType: eventType,
                              scheduledAt: scheduledDateTime,
                              isPrivate: isPrivate,
                            );

                            // 🏆 award points for creating a group
                            await _gamification.awardPoints(
                              points: 20,
                              action: 'create',
                              displayName:
                                  user?.phoneNumber ?? 'A Wekend Masti user',
                            );

                            navigator.pop();

                            // Show the invite code so the creator can share it.
                            if (isPrivate && mounted) {
                              showDialog(
                                context: rootContext,
                                builder: (_) => AlertDialog(
                                  title: const Text('Group Created 🎉'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                          'Share this invite code with people you want to join:'),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(result,
                                            style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 3,
                                                color: AppColors.primary)),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(rootContext),
                                      child: const Text('Got it'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(e
                                      .toString()
                                      .replaceAll('Exception: ', ''))),
                            );
                          }
                        },
                        child: Text(eventType == 'instant'
                            ? 'Create Group'
                            : 'Schedule Event'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- LEAVE / CANCEL ----------------

  Future<void> _confirmLeaveGroup(MeetupGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave group?'),
        content: Text(
            'You\'ll need to rejoin "${group.name}" to be part of it again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.leaveGroup(group.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You left "${group.name}"')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmCancelGroup(MeetupGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel this group?'),
        content: Text(
            'This will permanently remove "${group.name}" for everyone. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Group'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Group'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteGroup(group.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${group.name}" has been cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _leaveWaitlist(MeetupGroup group) async {
    try {
      await _service.leaveWaitlist(group.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from waitlist')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  // ---------------- MEMBERS SHEET ----------------

  void _showMembersSheet(MeetupGroup group, String? currentUid) {
    final isCreator = currentUid == group.createdBy;
    final onWaitlist = group.waitlistIds.contains(currentUid);
    final isMember = group.memberIds.contains(currentUid);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(group.name,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark)),
                      ),
                      if (group.isPrivate)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Private',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.purple)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        group.isScheduled ? Icons.calendar_today : Icons.bolt,
                        size: 14,
                        color: group.isScheduled
                            ? AppColors.primary
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        group.isScheduled
                            ? DateFormat('EEE, d MMM • h:mm a')
                                .format(group.scheduledAt!)
                            : 'Happening now',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: group.isScheduled
                              ? AppColors.primary
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (group.description.trim().isNotEmpty) ...[
                    Text(group.description,
                        style: TextStyle(
                            fontSize: 13.5, color: AppColors.textGrey)),
                    const SizedBox(height: 10),
                  ],
                  if (group.isPrivate && isCreator && group.inviteCode != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text('Invite code: ',
                              style: TextStyle(
                                  fontSize: 12.5, color: AppColors.textGrey)),
                          Text(group.inviteCode!,
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text('${group.memberIds.length}/${group.maxMembers} members'
                      '${group.waitlistIds.isNotEmpty ? ' • ${group.waitlistIds.length} waiting' : ''}',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textGrey)),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ...group.memberIds.map((memberUid) {
                          final memberName =
                              group.memberDetails[memberUid] ?? 'Member';
                          final isThisCreator = memberUid == group.createdBy;
                          final checkedIn = group.checkedInIds.contains(memberUid);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: memberUid == currentUid
                                ? null // can't chat with yourself
                                : () {
                                    Navigator.pop(sheetContext);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DirectChatScreen(
                                          otherUid: memberUid,
                                          otherName: memberName,
                                        ),
                                      ),
                                    );
                                  },
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              child: Icon(Icons.person,
                                  color: AppColors.primary, size: 20),
                            ),
                            title: Text(memberName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark)),
                            subtitle: Row(
                              children: [
                                if (isThisCreator)
                                  Text('Group creator',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600)),
                                if (checkedIn) ...[
                                  if (isThisCreator) const SizedBox(width: 6),
                                  Icon(Icons.check_circle,
                                      size: 13, color: AppColors.success),
                                  const SizedBox(width: 2),
                                  Text('Checked in',
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ],
                            ),
                            trailing: (isCreator && !isThisCreator)
                                ? IconButton(
                                    icon: const Icon(Icons.person_remove,
                                        color: Colors.red, size: 20),
                                    tooltip: 'Remove from group',
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: sheetContext,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Remove member?'),
                                          content: Text(
                                              'Remove $memberName from "${group.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red),
                                              onPressed: () => Navigator.pop(
                                                  context, true),
                                              child: const Text('Remove'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed != true) return;
                                      try {
                                        await _service.removeMember(
                                            group.id, memberUid);
                                        if (!mounted) return;
                                        Navigator.pop(sheetContext);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  '$memberName removed from group')),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(e
                                                  .toString()
                                                  .replaceAll(
                                                      'Exception: ', ''))),
                                        );
                                      }
                                    },
                                  )
                                : null,
                          );
                        }),
                        if (group.waitlistIds.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Waitlist',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textGrey)),
                          ...group.waitlistIds.map((waitUid) {
                            final waitName =
                                group.waitlistDetails[waitUid] ?? 'User';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.textGrey.withOpacity(0.1),
                                child: Icon(Icons.hourglass_empty,
                                    color: AppColors.textGrey, size: 18),
                              ),
                              title: Text(waitName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark)),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  if (isMember) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Group Chat'),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupChatScreen(group: group),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary),
                        icon: const Icon(Icons.qr_code, size: 18),
                        label:
                            Text(isCreator ? 'Show Check-In QR' : 'Check In'),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckinScreen(
                                  group: group, isCreator: isCreator),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (onWaitlist)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                        label: const Text('Leave Waitlist'),
                        onPressed: () => _leaveWaitlist(group),
                      ),
                    )
                  else if (isMember)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        icon: Icon(
                          isCreator ? Icons.delete_outline : Icons.logout,
                          size: 18,
                        ),
                        label:
                            Text(isCreator ? 'Cancel Group' : 'Leave Group'),
                        onPressed: () {
                          if (isCreator) {
                            _confirmCancelGroup(group);
                          } else {
                            _confirmLeaveGroup(group);
                          }
                        },
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _joinGroup(group);
                        },
                        child: Text(group.isFull ? 'Join Waitlist' : 'Join'),
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

  // ---------------- JOIN ----------------

  Future<void> _joinGroup(MeetupGroup group) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final result = await _service.joinGroup(
        group.id,
        displayName: user?.phoneNumber ?? 'A Wekend Masti user',
      );
      if (!mounted) return;

      if (result == 'waitlisted') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Group is full — you\'ve been added to the waitlist for "${group.name}"')),
        );
        return;
      }

      // 🏆 award points for joining a group
      await _gamification.awardPoints(
        points: 10,
        action: 'join',
        displayName: user?.phoneNumber ?? 'A Wekend Masti user',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined "${group.name}"!')),
      );

      if (group.eventType == 'instant' && result == 'joined') {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('You\'re in! 🎉'),
            content: Text(
                'You joined "${group.name}". Want to order food with the group now?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                child: const Text('Order Food'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('Meet Up',
            style: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: AppColors.textDark),
       actions: [
  IconButton(
    icon: Icon(Icons.leaderboard, color: AppColors.textDark),
    tooltip: 'Leaderboard',
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    ),
  ),

  StreamBuilder<bool>(
  stream: _service.isOrganizer(),
  builder: (context, snapshot) {
    if (!(snapshot.data ?? false)) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.notifications_active),
      tooltip: "Join Requests",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OrganizerRequestsScreen(),
          ),
        );
      },
    );
  },
),

  IconButton(
    icon: Icon(Icons.key, color: AppColors.textDark),
    tooltip: 'Join via invite code',
    onPressed: _showJoinViaCodeDialog,
  ),
],
      ),
      floatingActionButton: _position == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _showCreateGroupSheet,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Group',
                  style: TextStyle(color: Colors.white)),
            ),
      body: _buildBody(currentUid),
    );
  }

  Widget _buildBody(String? currentUid) {
    if (_loadingLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_locationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 48, color: AppColors.textGrey),
              const SizedBox(height: 12),
              Text(_locationError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    _permanentlyDenied ? _openSettingsAndRetry : _loadLocation,
                child:
                    Text(_permanentlyDenied ? 'Open Settings' : 'Try Again'),
              ),
              if (_permanentlyDenied) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _loadLocation,
                  child: const Text('I\'ve enabled it, retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<MeetupGroup>>(
      stream: _service.nearbyGroupsStream(
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        radiusKm: 10,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_outlined,
                      size: 56, color: AppColors.textGrey),
                  const SizedBox(height: 12),
                  Text('No groups nearby yet',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  Text('Be the first to create one!',
                      style: TextStyle(color: AppColors.textGrey)),
                  const SizedBox(height: 4),
                  Text('Have an invite code? Tap the key icon above.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
          );
        }

        final instantGroups =
            groups.where((g) => g.eventType == 'instant').toList();
        final scheduledGroups =
            groups.where((g) => g.eventType == 'scheduled').toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            if (instantGroups.isNotEmpty) ...[
              _sectionHeader('🔴 Happening Now'),
              const SizedBox(height: 10),
              ...instantGroups.map((g) => _groupCard(g, currentUid)),
              const SizedBox(height: 8),
            ],
            if (scheduledGroups.isNotEmpty) ...[
              _sectionHeader('📅 Upcoming Events'),
              const SizedBox(height: 10),
              ...scheduledGroups.map((g) => _groupCard(g, currentUid)),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Text(title,
          style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark)),
    );
  }

  Widget _groupCard(MeetupGroup group, String? currentUid) {
    final alreadyJoined = group.memberIds.contains(currentUid);
    final onWaitlist = group.waitlistIds.contains(currentUid);

    return GestureDetector(
      onTap: () => _showMembersSheet(group, currentUid),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(_categoryEmoji(group.category),
                      style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people_alt_rounded,
                              size: 13, color: AppColors.textGrey),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${group.category} • ${group.memberIds.length}/${group.maxMembers} joined'
                              '${group.waitlistIds.isNotEmpty ? ' • ${group.waitlistIds.length} waiting' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12.5, color: AppColors.textGrey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            group.isScheduled
                                ? Icons.calendar_today
                                : Icons.bolt,
                            size: 12,
                            color: group.isScheduled
                                ? AppColors.primary
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            group.isScheduled
                                ? DateFormat('EEE, d MMM • h:mm a')
                                    .format(group.scheduledAt!)
                                : 'Live now',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: group.isScheduled
                                  ? AppColors.primary
                                  : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {},
                  child: alreadyJoined
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Joined',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5)),
                        )
                      : onWaitlist
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Waitlisted',
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5)),
                            )
                          : ElevatedButton(
                              onPressed: () => _joinGroup(group),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: Text(group.isFull ? 'Waitlist' : 'Join'),
                            ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Tap to view members',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textLight,
                      fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(String category) {
    final c = category.toLowerCase();
    final keywordMap = <String, String>{
      'yoga': '🧘',
      'cricket': '🏏',
      'football': '⚽',
      'coffee': '☕',
      'gaming': '🎮',
      'game': '🎮',
      'study': '📚',
      'book': '📖',
      'trek': '🥾',
      'hike': '🥾',
      'run': '🏃',
      'gym': '🏋️',
      'workout': '🏋️',
      'music': '🎵',
      'movie': '🎬',
      'chess': '♟️',
      'dance': '💃',
      'party': '🎉',
      'walk': '🚶',
      'bike': '🚴',
      'cycling': '🚴',
      'art': '🎨',
      'photo': '📷',
    };
    for (final entry in keywordMap.entries) {
      if (c.contains(entry.key)) return entry.value;
    }
    return '👥';
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/colors.dart';
import '../models/meetup_group_model.dart';
import '../services/meetup_service.dart';
import '../services/gamification_service.dart';

class CheckinScreen extends StatefulWidget {
  final MeetupGroup group;
  final bool isCreator;

  const CheckinScreen({
    super.key,
    required this.group,
    required this.isCreator,
  });

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final MeetupService _service = MeetupService();
  final GamificationService _gamification = GamificationService();
  bool _processing = false;

  Future<void> _handleCode(String code) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final group = await _service.findGroupByCheckInCode(code);
      if (group == null) {
        _showMessage('Invalid check-in code');
        return;
      }
      final result = await _service.checkInMember(group.id);
      if (result == 'already_checked_in') {
        _showMessage('You\'re already checked in to "${group.name}"');
      } else {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        await _gamification.awardPoints(
          points: 15,
          action: 'checkin',
          displayName: group.memberDetails[uid] ?? 'User',
        );
        _showMessage('Checked in to "${group.name}"! 🎉');
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Check-In Code'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: '6-character code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final code = controller.text.trim();
              if (code.isNotEmpty) _handleCode(code);
            },
            child: const Text('Check In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          widget.isCreator ? 'Event Check-In Code' : 'Check In',
          style:
              TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800),
        ),
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      body: widget.isCreator ? _buildQrDisplay() : _buildScanner(),
    );
  }

  Widget _buildQrDisplay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Show this to attendees',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12)],
              ),
              child: QrImageView(
                data: widget.group.checkInCode ?? widget.group.id,
                size: 220,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.group.checkInCode ?? '',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Attendees can scan or type this code',
              style: TextStyle(fontSize: 12.5, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              _handleCode(barcodes.first.rawValue!);
            }
          },
        ),
        Positioned(
          bottom: 30,
          left: 24,
          right: 24,
          child: ElevatedButton.icon(
            onPressed: _showManualEntryDialog,
            icon: const Icon(Icons.keyboard),
            label: const Text('Enter code manually'),
          ),
        ),
        if (_processing)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black38,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

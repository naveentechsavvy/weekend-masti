import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import 'choice_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String verificationId;
  final int? resendToken;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _hasError = false;
  int _resendSeconds = 30;
  bool _canResend = false;

  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 30;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
        }
      });
      return _resendSeconds > 0;
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  // ---------------------------------------------------------
  // Called right after a successful Firebase sign-in (manual OTP
  // entry OR Android auto-verification). Checks Firestore to see
  // whether this phone number has ever signed in before:
  //   - New number  -> creates a "users/{uid}" doc
  //   - Known number -> just proceeds, existing profile stays as-is
  // This is the "Swiggy-style" returning-user recognition step.
  // ---------------------------------------------------------
  Future<void> _completeLogin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user!.uid;

      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final snapshot = await userDoc.get();

      bool isNewUser = false;

      if (!snapshot.exists) {
        isNewUser = true;
        await userDoc.set({
          'phone': widget.phone,
          'name': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('phone_number', widget.phone);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Get.snackbar(
        isNewUser ? 'Welcome!' : 'Welcome Back!',
        isNewUser ? 'Account created successfully' : 'Login successful',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      // 🔑 Branch point: send new users to a profile-completion step
      // instead of ChoiceScreen, once you build that screen.
      if (isNewUser) {
        Get.offAll(() => const ChoiceScreen());
      } else {
        Get.offAll(() => const ChoiceScreen());
      }
    } catch (e) {
      // IMPORTANT: without this catch, any Firestore error (missing
      // database, denied security rules, network issue) leaves the
      // screen stuck on "Verifying..." forever with no feedback.
      debugPrint('_completeLogin error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      Get.snackbar(
        'Error',
        'Something went wrong: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 6),
      );
    }
  }

  void _verifyOtp() async {
    if (_otp.length < 6) {
      setState(() => _hasError = true);
      HapticFeedback.vibrate();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: _otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _completeLogin();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      String message = 'Invalid OTP. Please try again.';
      if (e.code == 'invalid-verification-code') {
        message = 'Wrong OTP entered. Please check and retry.';
      } else if (e.code == 'session-expired') {
        message = 'OTP expired. Please resend OTP.';
      }

      Get.snackbar(
        'Wrong OTP',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _resendOtp() async {
    if (!_canResend) return;

    for (var c in _controllers) {
      c.clear();
    }
    setState(() {
      _hasError = false;
      _isLoading = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91${widget.phone}',
      timeout: const Duration(seconds: 60),
      forceResendingToken: widget.resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification (Android only) during resend window.
        // This also needs the same new-vs-returning check, so route
        // it through _completeLogin() just like manual entry.
        await FirebaseAuth.instance.signInWithCredential(credential);
        await _completeLogin();
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        Get.snackbar(
          'Error',
          e.message ?? 'Failed to resend OTP.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _currentVerificationId = verificationId;
        });
        _startResendTimer();
        _focusNodes[0].requestFocus();
        Get.snackbar(
          'OTP Sent',
          'New OTP sent to +91 ${widget.phone}',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _currentVerificationId = verificationId;
      },
    );
  }

  void _onOtpDigitChanged(int index, String value) {
    setState(() => _hasError = false);
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline,
                    size: 40, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 30),
            Text('Enter OTP',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 15, color: AppColors.textGrey),
                children: [
                  const TextSpan(text: 'OTP sent to '),
                  TextSpan(
                    text: '+91 ${widget.phone}',
                    style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _buildOtpBox(index)),
            ),
            if (_hasError) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 6),
                  Text('Invalid OTP. Please try again.',
                      style: TextStyle(
                          color: AppColors.error, fontSize: 13)),
                ],
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Verifying...',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ],
                      )
                    : const Text('Verify OTP',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: _canResend
                  ? GestureDetector(
                      onTap: _resendOtp,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: 'Didn\'t receive OTP? ',
                                style:
                                    TextStyle(color: AppColors.textGrey)),
                            TextSpan(
                                text: 'Resend OTP',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                              text: 'Resend OTP in ',
                              style: TextStyle(color: AppColors.textGrey)),
                          TextSpan(
                              text:
                                  '00:${_resendSeconds.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: _hasError ? AppColors.error : AppColors.textDark,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _hasError
              ? AppColors.error.withOpacity(0.05)
              : _controllers[index].text.isNotEmpty
                  ? AppColors.primary.withOpacity(0.07)
                  : AppColors.background,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _hasError
                  ? AppColors.error
                  : _controllers[index].text.isNotEmpty
                      ? AppColors.primary
                      : AppColors.divider,
              width: _controllers[index].text.isNotEmpty ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: _hasError ? AppColors.error : AppColors.primary,
                width: 2),
          ),
        ),
        onChanged: (value) => _onOtpDigitChanged(index, value),
      ),
    );
  }
}

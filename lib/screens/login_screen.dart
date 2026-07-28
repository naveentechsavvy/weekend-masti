import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import 'otp_screen.dart';
import 'choice_screen.dart';
 
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
 
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
 
  void _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
 
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${_phoneController.text.trim()}',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only) - fires when the OS detects
          // the SMS automatically, skipping manual OTP entry entirely.
          await FirebaseAuth.instance.signInWithCredential(credential);
 
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('phone_number', _phoneController.text.trim());
 
          if (!mounted) return;
          setState(() => _isLoading = false);
 
          Get.snackbar(
            'Login Successful!',
            'Welcome to Wekend Masti',
            backgroundColor: AppColors.success,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
 
          Get.offAll(() => const ChoiceScreen());
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
 
          // TEMPORARY DEBUG: show the raw Firebase error code + message
          // so we can see exactly why verification is failing.
          // Remove this once OTP is confirmed working and restore the
          // friendly messages below if you prefer.
          debugPrint('FirebaseAuthException code: ${e.code}');
          debugPrint('FirebaseAuthException message: ${e.message}');
 
          Get.snackbar(
            'Error: ${e.code}',
            e.message ?? 'No message provided',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 6),
          );
 
          /* Original friendly-message version — restore this after debugging:
          String message = 'Verification failed. Try again.';
          if (e.code == 'invalid-phone-number') {
            message = 'Invalid phone number format.';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many attempts. Please try later.';
          } else if (e.code == 'network-request-failed') {
            message = 'Network error. Check your connection.';
          }
          Get.snackbar(
            'Error',
            message,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
          */
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          Get.to(() => OtpScreen(
                phone: _phoneController.text.trim(),
                verificationId: verificationId,
                resendToken: resendToken,
              ));
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
 
      debugPrint('Unexpected error sending OTP: $e');
 
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 6),
      );
    }
  }
 
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text('Login',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                const SizedBox(height: 8),
                Text('Enter your mobile number to continue',
                    style:
                        TextStyle(fontSize: 16, color: AppColors.textGrey)),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    prefixText: '+91 ',
                    prefixIcon:
                        Icon(Icons.phone_android, color: AppColors.primary),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length != 10) {
                      return 'Enter valid 10 digit mobile number';
                    }
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                      return 'Enter a valid Indian mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Send OTP',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'OTP will be sent to your mobile number',
                    style:
                        TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
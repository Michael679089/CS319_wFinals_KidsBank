import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/family_model.dart';
import 'package:wfinals_kidsbank/database/models/family_payment_info_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class VerificationEmailPage extends StatefulWidget {
  final FamilyModel newFamilyModel;
  final FamilyPaymentInfoModel newFamilyPaymentInfoModel;

  const VerificationEmailPage({super.key, required this.newFamilyModel, required this.newFamilyPaymentInfoModel});

  @override
  State<VerificationEmailPage> createState() => _VerificationEmailPageState();
}

class _VerificationEmailPageState extends State<VerificationEmailPage> {
  bool _isLoading = false; // Track loading state for async operations

  // Functions:
  Future<void> _handleSendVerificationEmailBTN() async {
    var sendingEmailSucces = await AuthService.sendEmailVerification();

    if (sendingEmailSucces) {
      UtilityTopSnackBar.show(message: "Email Verification is sent", context: context);
    } else {
      UtilityTopSnackBar.show(message: "Error sending email", context: context, isError: true);
    }
  }

  Future<void> _handleCheckVerificationStatus() async {
    var navigator = Navigator.of(context);
    setState(() {
      _isLoading = true;
    });

    User? user = AuthService.getCurrentUser();
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        UtilityTopSnackBar.show(message: "Great, user email is verified, adding the Family & Payment Info to Firestore", context: context);
        FirestoreService.createFamily(widget.newFamilyModel);
        FirestoreService.createFamilyPaymentInfo(widget.newFamilyPaymentInfoModel);

        debugPrint("verifyEmailPage - email verification complete, user will be redirected to login page");
        navigator.pushReplacementNamed("/login-page");
      } else {
        UtilityTopSnackBar.show(message: "Oops, email not yet verified, please try again", context: context, isError: true);
      }
    } else {
      debugPrint("user is null");
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleReturnToRegisterFunction() async {
    var navigator = Navigator.of(context);

    // Step 1: Sign user out.
    AuthService.logoutAccount();

    try {
      if (mounted) {
        navigator.pop();
      } else {
        return;
      }
    } catch (e) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        debugPrint("verifyEmailPage - user went back");
        debugPrint("verifyEmailPage - user log out");
        _handleReturnToRegisterFunction();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFCA26),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'KidsBank',
                    style: GoogleFonts.fredoka(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Please verify your email address to continue.',
                          style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.newFamilyModel.email,
                          style: GoogleFonts.fredoka(fontSize: 18, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'A verification email has been sent to your inbox. '
                          'Click the link in the email to verify your account.',
                          style: GoogleFonts.fredoka(fontSize: 16, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _handleSendVerificationEmailBTN,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4e88cf),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'Resend Verification Email',
                                        style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () => _handleCheckVerificationStatus(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4e88cf),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'I’ve Verified My Email',
                                        style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Go back to Register Button
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _handleReturnToRegisterFunction,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                                      label: Text(
                                        'Back to Register',
                                        style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

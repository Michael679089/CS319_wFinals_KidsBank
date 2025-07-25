import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/family_model.dart';
import 'package:wfinals_kidsbank/database/models/family_payment_info_model.dart';

class VerificationEmailPage extends StatefulWidget {
  final String familyName;
  final String cardName;
  final String cardNumber;
  final String exp;
  final String ccv;

  const VerificationEmailPage({
    super.key,
    required this.familyName,
    required this.cardName,
    required this.cardNumber,
    required this.exp,
    required this.ccv,
  });

  @override
  State<VerificationEmailPage> createState() => _VerificationEmailPageState();
}

class _VerificationEmailPageState extends State<VerificationEmailPage> {
  bool _isLoading = false; // Track loading state for async operations

  AuthService myAuthService = AuthService();

  // Functions:
  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });
    var myMessenger = ScaffoldMessenger.of(context);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        myMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Verification email sent. Please check your inbox.',
              style: GoogleFonts.fredoka(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        myMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'No user signed in or email already verified.',
              style: GoogleFonts.fredoka(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      myMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send verification email: $e',
            style: GoogleFonts.fredoka(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkVerificationStatus(BuildContext myContext) async {
    debugPrint("verifyEmailPage - verifying if email is true");
    setState(() {
      _isLoading = true;
    });
    var navigator = Navigator.of(myContext);
    var myModalRoute = ModalRoute.of(myContext);
    var myMessenger = ScaffoldMessenger.of(myContext);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();

        // Step 1: Check if email is verified
        if (user.emailVerified) {
          if (myModalRoute == null) {
            debugPrint(
              "verifyEmailPage.dart - myModalRoute is false - please try again",
            );
            return;
          }

          // Step 2 - Email is indeed Verified - Add verified user to "Users" Collection.
          var myFirestoreAPI = FirestoreService();
          final args = myModalRoute.settings.arguments as Map<String, String>;
          var currentUserId = user.uid;
          FamilyModel newUser = FamilyModel(
            familyId: currentUserId,
            familyName: widget.familyName,
            email: user.email as String,
            createdAt: "",
          );
          await myFirestoreAPI.addAuthUserToFamilyCollection(newUser);

          // Step 2.1 - Add verified user's credit card information to "family-payment-info"
          var cardName = args["card-name"] as String;
          var cardNumber = args['card-number'] as String;
          var exp = args['card-exp'] as String;
          var ccv = args['card-ccv'] as String;

          if (cardName.isEmpty ||
              cardNumber.isEmpty ||
              exp.isEmpty ||
              ccv.isEmpty) {
            debugPrint("verifyEmailPage - card info missing");
          } else if (cardName.isNotEmpty ||
              cardNumber.isNotEmpty ||
              exp.isNotEmpty ||
              ccv.isNotEmpty) {
            FamilyPaymentInfoModel newPaymentInfoModel = FamilyPaymentInfoModel(
              familyId: currentUserId,
              cardName: cardName,
              cardNumber: cardNumber,
              ccv: ccv,
              exp: exp,
            );

            myFirestoreAPI.addCardPaymentInfo(newPaymentInfoModel);
            debugPrint("verifyEmailPage - added payment Card Info");
          }

          // Step 3 - Navigate route to Login

          navigator.pushNamedAndRemoveUntil(
            '/login-page',
            (route) => false, // Clear navigation stack
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Email not yet verified. Please check your inbox.',
                style: GoogleFonts.fredoka(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      myMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error checking verification status: $e',
            style: GoogleFonts.fredoka(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logoutAndReturnToRegister() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/register-page',
        (route) => false, // Clear navigation stack
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error logging out: $e',
            style: GoogleFonts.fredoka(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>;
    var email = args['register-email'];

    if (email == null) {
      Navigator.pop(context);
      return const Scaffold();
    }

    return Scaffold(
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
                  style: GoogleFonts.fredoka(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
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
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'A verification email has been sent to your inbox. '
                        'Click the link in the email to verify your account.',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _sendVerificationEmail,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4e88cf),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Resend Verification Email',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _checkVerificationStatus(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4e88cf),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'I’ve Verified My Email',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Go back to Register Button
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _logoutAndReturnToRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'Back to Register',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
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
    );
  }
}

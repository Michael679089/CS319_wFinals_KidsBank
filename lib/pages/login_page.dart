import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSignUpPressed = false;
  bool _isForgotPasswordPressed = false; // Added for forgot password link
  bool _isLoadingIndicatorActive = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();
  OverlayEntry? _overlayEntry;

  // My Services
  FirestoreService myFirestoreService = FirestoreService();
  NavigatorState? navigator;

  // Shared Preferences Values
  String savedEmail = '';
  String savedPassword = '';
  bool keepLoggedIn = false;

  // INITSTATE - runs before build, runs only once
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoLogin();
    });
  }

  // FUNCTIONS:

  void _removeAllOverlays() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _handleForgotPassword() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: Text(
          "Reset Password",
          style: GoogleFonts.fredoka(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter the email address to receive a password reset link.",
              style: GoogleFonts.fredoka(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _resetEmailController,
                decoration: InputDecoration(
                  hintText: "Email",
                  hintStyle: GoogleFonts.fredoka(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFAEDDFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.fredoka(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isLoadingIndicatorActive
                ? null
                : () async {
                    final email = _resetEmailController.text.trim();
                    if (email.isEmpty) {
                      UtilityTopSnackBar.show(
                        message: "Please enter an email address",
                        context: context,
                        isError: false,
                      );
                      return;
                    }
                    setState(() {
                      _isLoadingIndicatorActive = true;
                    });
                    try {
                      await AuthService.sendPasswordResetEmail(email);
                      Navigator.pop(ctx, true); // Close dialog on success
                      UtilityTopSnackBar.show(
                        message: "Password reset email sent successfully!",
                        context: context,
                        isError: false,
                      );
                    } on FirebaseAuthException catch (e) {
                      String errorMessage;
                      switch (e.code) {
                        case 'invalid-email':
                          errorMessage = "Invalid email address";
                          break;
                        case 'user-not-found':
                          errorMessage = "No account found for this email";
                          break;
                        default:
                          errorMessage =
                              "Error sending password reset email: ${e.message}";
                      }
                      UtilityTopSnackBar.show(
                        message: errorMessage,
                        context: context,
                        isError: true,
                      );
                      debugPrint("loginPage.dart - Forgot Password error: $e");
                    } catch (e) {
                      UtilityTopSnackBar.show(
                        message: "Unexpected error: $e",
                        context: context,
                        isError: true,
                      );
                      debugPrint(
                        "loginPage.dart - Unexpected Forgot Password error: $e",
                      );
                    } finally {
                      setState(() {
                        _isLoadingIndicatorActive = false;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4e88cf),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Text(
              "Send",
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      _removeAllOverlays();
      return;
    }
    // Do nothing if dialog was canceled
  }

  Future<bool> check_if_there_is_at_least_one_parent_in_family(
    String user_id,
  ) async {
    // Step 1: Check if a parent exist before navigation to account selector
    // this will be used to check if we should redirect user to parent-setup-page;
    var family_object = await FirestoreService.readFamily(user_id);
    var family_id = family_object?.id as String;
    ParentModel? parent_object = await FirestoreService.readParent(family_id);
    bool there_are_parents_in_family = (parent_object != null);
    return there_are_parents_in_family;
  }

  void _tryAutoLogin() async {
    setState(() {
      _isLoadingIndicatorActive = true;
    });

    debugPrint("loginPage.dart - Trying Auto Login START");

    NavigatorState navigator = Navigator.of(context);

    // Step 1: Get the keepLoggedIn shared Preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      keepLoggedIn = prefs.getBool('keepLoggedIn') ?? false;

      if (keepLoggedIn) {
        var doesFamilyCollectionExist =
            await FirestoreService.doesFirestoreCollectionExist("family");

        if (doesFamilyCollectionExist) {
          var user = AuthService.getCurrentUser();

          var is_user_authenticated = (user != null);

          if (is_user_authenticated) {
            var user_Id = user.uid;

            if (user.emailVerified) {
              var there_are_parents_in_family =
                  await check_if_there_is_at_least_one_parent_in_family(
                    user_Id,
                  );
              navigator.pushNamed(
                "/account-selector-page",
                arguments: {
                  "user-id": user_Id,
                  "there-are-parent-in-family": there_are_parents_in_family,
                },
              );
              return;
            } else {
              debugPrint("loginPage - email not verified");
            }
          } else {
            debugPrint("loginPage - no users logged in");
          }
        }
        debugPrint("loginPage - redirect to registerPage ");
        navigator.pushNamed(
          "/register-page",
          arguments: {"is-broken-register": true},
        );
      } else {
        debugPrint("loginPage - keepLoggedIn is false");

        // Step 2 - send authenticated-unverified users to register page
        var user = AuthService.getCurrentUser();
        var is_user_authenticated_before_register = (user != null);
        if (is_user_authenticated_before_register &&
            user.emailVerified == false) {
          debugPrint(
            "loginPage - redirect user due to user being authenticated but not verified",
          );
          navigator.pushNamed(
            "/register-page",
            arguments: {"is-broken-register": true},
          );
        } else {
          debugPrint("loginPage - user is already verified");
        }
      }
    } catch (e) {
      debugPrint("ERROR: during auto login $e");
    } finally {
      setState(() {
        _isLoadingIndicatorActive = false;
      });
    }

    debugPrint("loginPage.dart - Trying Auto Login END");
  }

  void _updateKeepLoggedInValue(bool val) async {
    debugPrint("loginPage - updated keepLoggedIn to $val");
    setState(() {
      keepLoggedIn = val;
    });
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      UtilityTopSnackBar.show(
        context: context,
        message: 'Please fill in both email and password',
        isError: true,
      );
      return; // Stop execution if fields are empty
    }
    setState(() {
      _isLoadingIndicatorActive = true;
    });

    var navigator = Navigator.of(context);
    debugPrint("loginPage.dart - _handleLogin is called");

    var email = _emailController.text;
    var password = _passwordController.text;

    var loginResponse = await AuthService.loginAccount(email, password);

    if (loginResponse["status"] == "success") {
      var user = AuthService.getCurrentUser();
      String user_id = user!.uid;
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('keepLoggedIn', keepLoggedIn);
      var there_are_parents_in_family =
          await check_if_there_is_at_least_one_parent_in_family(user_id);

      debugPrint("LoginPage - successful login");
      navigator.pushNamed(
        "/account-selector-page",
        arguments: {
          "user-id": user_id,
          "there-are-parent-in-family": there_are_parents_in_family,
        },
      );
    } else if (loginResponse["status"] == "unverified") {
      debugPrint(
        "loginPage - user is found unverified. Sending user to register page",
      );
      navigator.pushNamed(
        "/register-page",
        arguments: {"is-broken-register": true},
      );
      UtilityTopSnackBar.show(
        message:
            "ERROR: user is found unverified. Sending user to register page",
        context: context,
        isError: false,
      );
    } else {
      debugPrint("loginPage - an error occurred during login");
      UtilityTopSnackBar.show(
        message: "Please fill in all fields to continue",
        context: context,
        isError: true,
      );
    }

    setState(() {
      _isLoadingIndicatorActive = false;
    });
  }

  // The DISPOSE
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  // Custom widget variables
  Widget _buildInputField(
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFAEDDFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton(
        onPressed: _isLoadingIndicatorActive ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4e88cf),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Text(
          'Log In',
          style: GoogleFonts.fredoka(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    navigator = Navigator.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        navigator?.pushNamed("/welcome-page");
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFCA26),
        body: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title Section
                    Text(
                      'KidsBank',
                      style: GoogleFonts.fredoka(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Input Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'E-Mail',
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInputField(_emailController),
                          const SizedBox(height: 16),
                          Text(
                            'Password',
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInputField(
                            _passwordController,
                            isPassword: true,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTapDown: _isLoadingIndicatorActive
                                  ? null
                                  : (_) => setState(
                                      () => _isForgotPasswordPressed = true,
                                    ),
                              onTapUp: _isLoadingIndicatorActive
                                  ? null
                                  : (_) {
                                      setState(
                                        () => _isForgotPasswordPressed = false,
                                      );
                                      _handleForgotPassword();
                                    },
                              onTapCancel: _isLoadingIndicatorActive
                                  ? null
                                  : () => setState(
                                      () => _isForgotPasswordPressed = false,
                                    ),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isForgotPasswordPressed
                                      ? const Color(0xFF4E88CF)
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: _buildLoginButton(),
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: keepLoggedIn,
                                onChanged: _isLoadingIndicatorActive
                                    ? null
                                    : (val) {
                                        setState(() {
                                          _updateKeepLoggedInValue(
                                            val ?? false,
                                          );
                                        });
                                      },
                              ),
                              Text(
                                'Keep us logged in',
                                style: GoogleFonts.fredoka(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Register Button
                    Text('Need an account?', style: GoogleFonts.inter()),
                    GestureDetector(
                      onTapDown: _isLoadingIndicatorActive
                          ? null
                          : (_) => setState(() => _isSignUpPressed = true),
                      onTapUp: _isLoadingIndicatorActive
                          ? null
                          : (_) {
                              setState(() => _isSignUpPressed = false);
                              navigator?.pushNamed(
                                "/register-page",
                                arguments: {
                                  "email-text-value": _emailController.text
                                      .trim(),
                                  "password-text-value": _passwordController
                                      .text
                                      .trim(),
                                  "is-broken-register": false,
                                },
                              );
                            },
                      onTapCancel: _isLoadingIndicatorActive
                          ? null
                          : () => setState(() => _isSignUpPressed = false),
                      child: Text(
                        'Sign up',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _isSignUpPressed
                              ? const Color(0xFF4E88CF)
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoadingIndicatorActive)
              Container(
                color: Colors.black.withAlpha(150),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4e88cf),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

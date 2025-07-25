import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';

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
  AuthService myAuthService = AuthService();
  FirestoreService myFirestoreService = FirestoreService();
  NavigatorState? navigator;

  // Saved Credentials
  String? savedEmail = "";
  String? savedPassword = "";
  bool _keepLoggedIn = false;

  // FUNCTIONS:

  void _invokeTopSnackBar(String message, {bool isError = true}) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: GoogleFonts.fredoka(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }

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
                      _invokeTopSnackBar(
                        "Please enter an email address",
                        isError: true,
                      );
                      return;
                    }
                    setState(() {
                      _isLoadingIndicatorActive = true;
                    });
                    try {
                      await myAuthService.sendPasswordResetEmail(email);
                      Navigator.pop(ctx, true); // Close dialog on success
                      _invokeTopSnackBar(
                        "Password reset email sent successfully!",
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
                      _invokeTopSnackBar(errorMessage, isError: true);
                      debugPrint("loginPage.dart - Forgot Password error: $e");
                    } catch (e) {
                      _invokeTopSnackBar("Unexpected error: $e", isError: true);
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

  void _tryAutoLogin() async {
    debugPrint("loginPage.dart - Trying Auto Login");

    NavigatorState navigator = Navigator.of(context);

    // Step 1: Try login using Shared Preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      savedEmail = prefs.getString('savedEmail');
      savedPassword = prefs.getString('savedPassword');
      _keepLoggedIn = prefs.getBool('keepLoggedIn') ?? false;

      if (_keepLoggedIn && savedEmail != null && savedPassword != null) {
        var savedEmailAsString = savedEmail as String;
        var savedPasswordAsString = savedPassword as String;
        myAuthService.loginAccountWithEmailAndPass(
          savedEmailAsString,
          savedPasswordAsString,
        );

        var user = myAuthService.getCurrentUser();
        if (user == null) return;
        var userId = user.uid;
        var familyName = await myFirestoreService.fetchFamilyNameOfUserID(
          user.uid,
        );

        navigator.pushNamed(
          "/account-selector-page",
          arguments: {"family-name": familyName, "family-user-id": userId},
        );
        debugPrint(
          "loginPage.dart - Auto Login successful (via Shared Preferences) - redirected to account-selector-page",
        );
        return;
      } else {
        debugPrint(
          "loginPage.dart - SharedPreferences Failed - $savedEmail - $savedPassword",
        );
      }
    } catch (e) {
      debugPrint("ERROR: loginPage.dart - SharedPreferences error: $e");
    }

    // Alt Step 1: If Shared Preferences is false, try AuthCurrentUser
    try {
      var user = myAuthService.getCurrentUser();
      debugPrint("loginPage.dart - Trying to get currentUser");
      debugPrint("loginPage.dart - Result: ${user?.email}");

      if (user != null) {
        debugPrint("loginPage.dart - currentUser Found! -> ${user.email}");

        // Step 2: Check if user is verified
        if (user.emailVerified) {
          setState(() {
            _isLoadingIndicatorActive = true;
          });

          if (!await myFirestoreService.checkIfTableCollectionExist("family")) {
            debugPrint(
              "loginPage - ERROR: users collection doesn't exist. - Possibly user quit after verification - redirecting to /register-page",
            );
            navigator.pushReplacementNamed(
              "/register-page",
              arguments: {"is-broken-register": true},
            );
            return;
          }

          var familyName = await myFirestoreService.fetchFamilyNameOfUserID(
            user.uid,
          );
          var userId = user.uid;
          setState(() {
            _isLoadingIndicatorActive = false;
          });

          navigator.pushNamed(
            "/account-selector-page",
            arguments: {"family-name": familyName, "family-user-id": userId},
          );
          debugPrint(
            "loginPage.dart - Auto Login successful (via Auth.CurrentUser) - redirected to account-selector-page",
          );
        } else {
          navigator.pushNamed(
            "/verify-email-page",
            arguments: {"register-email": user.email.toString()},
          );
          debugPrint(
            "loginPage.dart - Oops account still not verified - Redirected to verify-email-page",
          );
        }
      } else {
        debugPrint("loginPage.dart - no currentUser found, User can login");
      }
    } catch (e) {
      debugPrint("ERROR: loginPage.dart - failed getting currentUser: $e");
    }
  }

  Future<void> _handleLogin() async {
    debugPrint("loginPage.dart - handleLogin is called");

    // Step 1: Checking fields
    if (_passwordController.text.isEmpty || _emailController.text.isEmpty) {
      _invokeTopSnackBar("Please enter both email and password", isError: true);
      return;
    }

    setState(() {
      _isLoadingIndicatorActive = true;
    });

    // Step 2: Try login account details
    try {
      await myAuthService.loginAccountWithEmailAndPass(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Step 3: Check if user wants to save their login details in Shared Preferences
      if (_keepLoggedIn) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('savedEmail', _emailController.text.trim());
        await prefs.setString('savedPassword', _passwordController.text.trim());
        await prefs.setBool('keepLoggedIn', _keepLoggedIn);
        debugPrint(
          "loginPage.dart - Saved to SharedPreferences: ${prefs.getString('savedEmail')} | ${prefs.getString('savedPassword')} | keepLoggedIn: ${prefs.getBool('keepLoggedIn')}",
        );
      }

      var user = myAuthService.getCurrentUser();
      if (user != null) {
        if (user.emailVerified) {
          var familyName = await myFirestoreService.fetchFamilyNameOfUserID(
            user.uid,
          );
          navigator?.pushNamed(
            "/account-selector-page",
            arguments: {"family-name": familyName, "family-user-id": user.uid},
          );
        } else {
          navigator?.pushNamed(
            "/verify-email-page",
            arguments: {"register-email": _emailController.text.trim()},
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found for this email";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address";
          break;
        default:
          errorMessage = "Login failed: ${e.message}";
      }
      _invokeTopSnackBar(errorMessage, isError: true);
      debugPrint("ERROR: loginPage.dart - Login error: $e");
    } catch (e) {
      _invokeTopSnackBar("Unexpected error: $e", isError: true);
      debugPrint("ERROR: loginPage.dart - Unexpected login error: $e");
    } finally {
      setState(() {
        _isLoadingIndicatorActive = false;
      });
    }
  }

  // The DISPOSE
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  // INITSTATE - runs before build, runs only once
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoLogin();
    });
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

    return Scaffold(
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
                        _buildInputField(_passwordController, isPassword: true),
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
                              value: _keepLoggedIn,
                              onChanged: _isLoadingIndicatorActive
                                  ? null
                                  : (val) {
                                      setState(
                                        () => _keepLoggedIn = val ?? false,
                                      );
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
                  // Register Section
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
                                "password-text-value": _passwordController.text
                                    .trim(),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4e88cf)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

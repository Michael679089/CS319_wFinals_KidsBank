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
  bool _isLoadingIndicatorActive = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // My Services
  AuthService myAuthService = AuthService();
  FirestoreAPI myFirestoreAPI = FirestoreAPI();
  NavigatorState? navigator;

  // Saved Credentials
  String? savedEmail = "";
  String? savedPassword = "";
  bool _keepLoggedIn = false;

  // FUNCTIONS:

  void _invokeTopSnackBar(String message, {bool isError = true}) {
    final snackBar = SnackBar(
      content: Text(message, style: GoogleFonts.fredoka(color: Colors.white)),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }

  void _tryAutoLogin() async {
    debugPrint("loginPage.dart - Trying Auto Login");

    NavigatorState navigator = Navigator.of(context);

    // Step 1: Try login in using Shared Preferences.
    try {
      final prefs = await SharedPreferences.getInstance();
      savedEmail = prefs.getString('savedEmail');
      savedPassword = prefs.getString('savedPassword');
      _keepLoggedIn = prefs.getBool('keepLoggedIn') ?? false;

      if (_keepLoggedIn) {
        navigator.pushNamed("/account-selector-page");
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
      debugPrint("ERROR: loginPage.dart - an error occured here: $e");
    }

    // Alt Step 1: If Shared Preferences is false, try AuthCurrentUser
    try {
      var user = myAuthService.getCurrentUser();
      debugPrint("loginPage.dart - Trying to get currentUser");
      debugPrint("loginPage.dart - Result: ${user.toString()}");

      if (user != null) {
        debugPrint("loginPage.dart - currentUser Found! -> ${user.email}");

        // Step 2: Check if user is verified.
        if (user.emailVerified) {
          setState(() {
            _isLoadingIndicatorActive = true;
          });
          var familyName = await myFirestoreAPI.fetchFamilyNameOfUserID(
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

    if (_passwordController.text.isEmpty || _emailController.text.isEmpty) {
      _invokeTopSnackBar("ERROR: some fields are missing");
      return;
    }

    try {
      myAuthService.loginAccountWithEmailAndPass(
        _emailController.text,
        _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("ERROR: Logging in to Auth $e");
      return;
    }
    debugPrint(
      "loginPage.dart - Login Success - currentuser:${myAuthService.getCurrentUser()}",
    );

    if (_keepLoggedIn) {
      debugPrint(savedEmail);
      debugPrint(savedPassword);
      debugPrint(_keepLoggedIn.toString());

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('savedEmail', _emailController.text);
      prefs.setString('savedPassword', _passwordController.text);
      prefs.setBool('keepLoggedIn', _keepLoggedIn);
      debugPrint(
        "loginPage.dart - Added or Setted strings to SharedPreferences",
      );
      debugPrint(
        "loginPage.dart - savedemail - ${prefs.getString("savedEmail")} | savedemail - ${prefs.getString("savedPassword")} | _keepLoggedIn - ${prefs.getBool("keepLoggedIn")} |",
      );
    }
  }

  // The DISPOSE
  @override
  void dispose() {
    super.dispose();
  }

  // INITSTATE - runs before build, runs only once.
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoLogin(); // Load credentials synchronously
    });
  }

  // BUILD Function

  // custom widget variables:
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
        onPressed: _handleLogin,
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
                  // Title Section ---
                  Text(
                    'KidsBank',
                    style: GoogleFonts.fredoka(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Input Section ---
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
                              style: GoogleFonts.fredoka(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Register Section ---
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
                                "email-text-value": _emailController.text,
                                "password-text-value": _passwordController.text,
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
              color: Colors.black.withOpacity(0.5),
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

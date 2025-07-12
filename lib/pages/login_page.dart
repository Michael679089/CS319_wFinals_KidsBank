import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_page.dart';
import 'kids_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _keepLoggedIn = false;
  bool _isSignUpPressed = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFamilyName = prefs.getString('savedFamilyName') ?? '';
    final savedPassword = prefs.getString('savedPassword') ?? '';
    final keepLoggedIn = prefs.getBool('keepLoggedIn') ?? false;

    if (keepLoggedIn) {
      setState(() {
        _familyNameController.text = savedFamilyName;
        _passwordController.text = savedPassword;
        _keepLoggedIn = true;
      });
    }
  }

  Future<void> _handleLogin() async {
  final familyName = _familyNameController.text.trim();
  final password = _passwordController.text;

  if (familyName.isEmpty || password.isEmpty) {
    if (!mounted) return;
    _showTopSnackBar('Family name and password are required!');
    return;
  }

  try {
    // ✅ AWAIT 1: Firebase query
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('family_name', isEqualTo: familyName)
        .limit(1)
        .get();

    // Check after await
    if (!mounted) return;

    if (userSnapshot.docs.isEmpty) {
      _showTopSnackBar('Family name not found!');
      return;
    }

    final userEmail = userSnapshot.docs.first.get('email');

    // AWAIT 2: Firebase Auth
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: userEmail,
      password: password,
    );

    // Check again after await
    if (!mounted) return;

    if (_keepLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('savedFamilyName', familyName);
      await prefs.setString('savedPassword', password);
      await prefs.setBool('keepLoggedIn', true);
    }

    // Safe to use context now
    _showTopSnackBar('Login successful!', isError: false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const KidsDashboard()),
    );
  } catch (e) {
    if (!mounted) return;
    _showTopSnackBar('Login failed: ${e.toString()}');
  }
}
  void _showTopSnackBar(String message, {bool isError = true}) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: GoogleFonts.fredoka(color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFCA26),
      body: Center(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Family Name',
                        style: GoogleFonts.fredoka(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildInputField(_familyNameController),
                    const SizedBox(height: 16),
                    Text('Password',
                        style: GoogleFonts.fredoka(
                            fontSize: 20, fontWeight: FontWeight.bold)),
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
                          onChanged: (val) {
                            setState(() => _keepLoggedIn = val ?? false);
                          },
                        ),
                        Text('Keep us logged in', style: GoogleFonts.fredoka()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Need an account?', style: GoogleFonts.inter()),
              GestureDetector(
                onTapDown: (_) => setState(() => _isSignUpPressed = true),
                onTapUp: (_) {
                  setState(() => _isSignUpPressed = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupPage()),
                  );
                },
                onTapCancel: () => setState(() => _isSignUpPressed = false),
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
    );
  }

  Widget _buildInputField(TextEditingController controller,
      {bool isPassword = false}) {
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
}

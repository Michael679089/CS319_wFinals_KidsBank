import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/pages/authentication_page.dart';
import 'kids_dashboard.dart';

class KidsLoginPage extends StatefulWidget {
  const KidsLoginPage({super.key});

  @override
  State<KidsLoginPage> createState() => _KidsLoginPageState();
}

class _KidsLoginPageState extends State<KidsLoginPage> {
  final TextEditingController passwordController = TextEditingController();

  String kidName = '';
  String avatarPath = '';
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadKidData();
  }

  Future<void> _loadKidData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('kids')
        .where('user_id', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      setState(() {
        kidName = doc['firstName'];
        avatarPath = doc['avatar'];
        userId = user.uid;
      });
    }
  }

  Future<void> _login() async {
    final password = passwordController.text.trim();

    if (password.isEmpty) {
      _showSnackbar("Password cannot be empty.");
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('kids')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty || snapshot.docs.first['password'] != password) {
        _showSnackbar("Incorrect password.");
        return;
      }

      _showSnackbar("Login successful!", isError: false);

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KidsDashboard()),
      );
    } catch (e) {
      _showSnackbar("Error: ${e.toString()}");
    }
  }

  void _showSnackbar(String message, {bool isError = true}) {
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {},
      child: Scaffold(
        backgroundColor: const Color(0xFFFFCA26),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with shadow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.3 * 255).toInt()),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(10, 12),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundImage: avatarPath.isNotEmpty
                            ? AssetImage(avatarPath)
                            : const AssetImage('assets/avatar1.png'),
                        radius: 70,
                        backgroundColor: const Color(0xFF4E88CF),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      kidName.isNotEmpty ? "Hi $kidName!" : "Hi!",
                      style: GoogleFonts.fredoka(
                        fontSize: 58.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel("Please input your password"),
                    const SizedBox(height: 8),
                    _buildPasswordField(passwordController),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFCA26),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.black, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Log in',
                              style: GoogleFonts.fredoka(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthenticationPage())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          label: Text(
                            "Back",
                            style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.fredoka(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        children: const [
          TextSpan(
            text: " *",
            style: TextStyle(color: Colors.black, fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        obscuringCharacter: '•',
        keyboardType: TextInputType.visiblePassword,
        style: GoogleFonts.fredoka(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

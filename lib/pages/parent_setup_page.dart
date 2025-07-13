import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'kids_setup_page.dart';
import 'login_page.dart';

class ParentSetupPage extends StatefulWidget {
  const ParentSetupPage({super.key});

  @override
  State<ParentSetupPage> createState() => _ParentSetupPageState();
}

class _ParentSetupPageState extends State<ParentSetupPage> {
  String selectedAvatar = 'assets/avatar1.png';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _showAvatarPicker() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: [
                for (var i = 1; i <= 6; i++)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAvatar = 'assets/avatar$i.png';
                      });
                      Navigator.of(context).pop();
                    },
                    child: CircleAvatar(
                      backgroundImage: AssetImage('assets/avatar$i.png'),
                      radius: 30,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = nameController.text.trim();
    final dob = dobController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || dob.isEmpty || password.isEmpty) {
      _showSnackbar('All fields are required', isError: true);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackbar('User not authenticated', isError: true);
        return;
      }

      await FirebaseFirestore.instance.collection('parents').doc(user.uid).set({
        'firstname': name,
        'date_of_birth': dob,
        'password': password,
        'avatar': selectedAvatar,
        'user_id': user.uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      _showSnackbar('Setup completed successfully!', isError: false);

      await Future.delayed(const Duration(milliseconds: 1500));
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const KidsSetupPage()),
      );
    } catch (e) {
      _showSnackbar('Error saving data: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    final overlay = Overlay.of(context);
    final color = isError ? Colors.red : Colors.green;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewInsets.top + 40,
        left: 20,
        right: 20,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontFamily: GoogleFonts.fredoka().fontFamily,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1980),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4E88CF),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF4E88CF)),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      dobController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log Out'),
            content: const Text('Do you want to log out and return to the login page?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        );

        if (shouldLogout == true && context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFCA26),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(selectedAvatar),
                      radius: 60,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: _showAvatarPicker,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.purple,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Set up your account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: GoogleFonts.fredoka().fontFamily,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F1F1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    children: [
                      _buildLabel('Name'),
                      _buildField(nameController),
                      const SizedBox(height: 20),
                      _buildLabel('Date of birth'),
                      _buildField(dobController, onTap: _pickDate, readOnly: true),
                      const SizedBox(height: 20),
                      _buildLabel('Password'),
                      _buildField(
                        passwordController,
                        obscure: true,
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4E88CF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.black, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              fontFamily: GoogleFonts.fredoka().fontFamily,
                              color: Colors.black,
                            ),
                          ),
                        ),
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

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: GoogleFonts.fredoka().fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller, {
    bool obscure = false,
    bool readOnly = false,
    int? maxLength,
    TextInputType? keyboardType,
    void Function()? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFAEDDFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        maxLength: maxLength,
        keyboardType: keyboardType,
        onTap: onTap,
        obscuringCharacter: '*',
        style: TextStyle(
          fontFamily: GoogleFonts.fredoka().fontFamily,
          fontSize: 24,
        ),
        decoration: const InputDecoration(
          counterText: "",
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

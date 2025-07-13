import 'dart:io'; // For exit(0)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/pages/login_page.dart';
import 'package:wfinals_kidsbank/pages/signup_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async  {
        if (!didPop) {
          final shouldExit = await _showExitConfirmation(context);
          if (shouldExit) {
            exit(0);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFCA26),
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Welcome to',
                          style: TextStyle(
                            fontFamily: GoogleFonts.fredoka().fontFamily,
                            fontSize: 36.1,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'KidsBank',
                          style: TextStyle(
                            fontFamily: GoogleFonts.fredoka().fontFamily,
                            fontSize: 71.4,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Image.asset(
                      'assets/pig.png',
                      width: 350,
                      height: 350,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 95),
                  Transform.translate(
                    offset: const Offset(8, -21),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Image.asset(
                        'assets/dots.png',
                        width: 140,
                        height: 159,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),

              // Overlapping Button Container
              Positioned(
                bottom: 160,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4e88cf),
                            foregroundColor: const Color(0xFFefe6e8),
                            side: const BorderSide(color: Colors.black, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 25,
                              fontFamily: GoogleFonts.fredoka().fontFamily,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 25,
                              fontFamily: GoogleFonts.fredoka().fontFamily,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Exit App',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to exit the app?',
              style: GoogleFonts.fredoka(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.fredoka(color: Colors.grey[700]),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    exit(0); // exits the app
                  });
                },
                child: Text(
                  'Exit',
                  style: GoogleFonts.fredoka(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

import 'dart:io'; // For exit(0)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // FUNCTIONS:

  Future<bool> _showExitConfirmation(BuildContext context) async {
    var navigator = Navigator.of(context);

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Exit App', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
            content: Text('Are you sure you want to exit the app?', style: GoogleFonts.fredoka()),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(false),
                child: Text('Cancel', style: GoogleFonts.fredoka(color: Colors.grey[700])),
              ),
              TextButton(
                onPressed: () {
                  navigator.pop(true);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    exit(0); // user exits the app
                  });
                },
                child: Text('Exit', style: GoogleFonts.fredoka(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _goToRegisterPage(BuildContext context) async {
    var myNavigator = Navigator.of(context);

    try {
      AuthService.logoutAccount();
      debugPrint("welcomePage - user successfully logged out");
    } catch (e) {
      debugPrint("welcomePage - there's no logged in user. Continuing");
    }

    myNavigator.pushNamed("/register-page", arguments: {"is-broken-register": false});
  }

  void _goToLoginPage(BuildContext context) async {
    var myNavigator = Navigator.of(context);

    myNavigator.pushNamed("/login-page");
  }

  // BUILD Function:

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use different layouts for mobile and tablet/desktop
              if (constraints.maxWidth < 600) {
                return _buildMobileLayout(context);
              } else {
                return _buildDesktopLayout(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    // Your original vertical layout for mobile
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    'Welcome to',
                    style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily, fontSize: 36.1, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'KidsBank',
                    style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily, fontSize: 71.4, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                ],
              ),
            ),
            Center(child: Image.asset('assets/pig.png', width: 350, height: 350, fit: BoxFit.contain)),
            const SizedBox(height: 95),
          ],
        ),
        Positioned(bottom: 160, left: 0, right: 0, child: _buildButtonContainer(context)),
        Positioned(
          right: 8,
          bottom: -21,
          child: ClipRect(child: Image.asset('assets/dots.png', width: 140, height: 159, fit: BoxFit.contain)),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side - Pig image and title
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to',
                  style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily, fontSize: 42, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'KidsBank',
                  style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily, fontSize: 82, fontWeight: FontWeight.w700, color: Colors.black),
                ),
                const SizedBox(height: 40),
                Image.asset('assets/pig.png', width: 400, height: 400, fit: BoxFit.contain),
              ],
            ),
          ),

          // Right side - Buttons container
          Padding(padding: const EdgeInsets.only(left: 40), child: _buildButtonContainer(context)),
        ],
      ),
    );
  }

  Widget _buildButtonContainer(BuildContext context) {
    return Container(
      width: 400, // Fixed width for the button container
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _goToLoginPage(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4e88cf),
                foregroundColor: const Color(0xFFefe6e8),
                side: const BorderSide(color: Colors.black, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'Log In',
                style: TextStyle(fontSize: 25, fontFamily: GoogleFonts.fredoka().fontFamily, fontWeight: FontWeight.w700, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _goToRegisterPage(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'Register',
                style: TextStyle(fontSize: 25, fontFamily: GoogleFonts.fredoka().fontFamily, fontWeight: FontWeight.w700, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/pages/kids_dashboard.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFCA26),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20), // reduced from 40

                // Welcome texts
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

                // Removed: const SizedBox(height: 5),

                // Pig image
                Center(
                  child: Image.asset(
                    'assets/pig.png',
                    width: 350,
                    height: 350,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 95), 

                // Dotted line
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
                            MaterialPageRoute(builder: (context) => const KidsDashboard()),
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
                            MaterialPageRoute(builder: (context) => const Placeholder()),
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
    );
  }
}

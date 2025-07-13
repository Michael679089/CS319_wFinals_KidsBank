import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/pages/kids_login_page.dart';
import 'welcomepage.dart';
// ignore: unnecessary_import
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'parent_login_page.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  String? selectedName;
  String? selectedRole;

  String parentName = '';
  String parentAvatar = '';
  String userId = '';
  List<Map<String, dynamic>> kids = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final parentDoc = await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .get();

      if (parentDoc.exists) {
        setState(() {
          parentName = parentDoc['firstname'];
          parentAvatar = parentDoc['avatar'];
          userId = user.uid;
        });
      }

      final kidsSnapshot = await FirebaseFirestore.instance
          .collection('kids')
          .where('user_id', isEqualTo: user.uid)
          .get();

      setState(() {
        kids = kidsSnapshot.docs.map((doc) => doc.data()).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
  canPop: false, // Prevent back navigation
   onPopInvokedWithResult: (didPop, result) async {
    // Do nothing when back is pressed
  },
    child: Scaffold(
      backgroundColor: const Color(0xFFFFCA26),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Hi!",
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      fontFamily: GoogleFonts.fredoka().fontFamily,
                    ),
                  ),
                  Text(
                    "Who is using?",
                    style: TextStyle(
                      fontSize: 28.8,
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.fredoka().fontFamily,
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// Main Container (full height)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCA26),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: IntrinsicHeight(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Parent avatar + label
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedName = parentName;
                                            selectedRole = "parent";
                                          });
                                        },
                                        child: Row(
                                          children: [
                                              Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withAlpha((0.3 * 255).toInt()),
                                                        blurRadius: 10,
                                                        spreadRadius: 2,
                                                        offset: const Offset(0, 5),
                                                      ),
                                                    ],
                                                  ),
                                            child: CircleAvatar(
                                              backgroundImage: AssetImage(parentAvatar),
                                              radius: 60,
                                              backgroundColor: selectedName == parentName && selectedRole == "parent"
                                                  ? Colors.blueAccent
                                                  : Colors.transparent,
                                            ),
                                          ),
                                            const SizedBox(width: 16),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  parentName,
                                                  style: TextStyle(
                                                    fontSize: 34,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: GoogleFonts.fredoka().fontFamily,
                                                  ),
                                                ),
                                                Text(
                                                  "[Parent]",
                                                  style: TextStyle(
                                                    fontSize: 34,
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily: GoogleFonts.fredoka().fontFamily,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      // Kids avatars
                                      Wrap(
                                        alignment: WrapAlignment.start,
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: kids.map((kid) {
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedName = kid['firstName'];
                                                selectedRole = "kid";
                                              });
                                            },
                                            child: Column(
                                              children: [
                                              Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withAlpha((0.3 * 255).toInt()),
                                                        blurRadius: 10,
                                                        spreadRadius: 2,
                                                        offset: const Offset(0, 5),
                                                      ),
                                                    ],
                                                  ),
                                               child: CircleAvatar(
                                                  backgroundImage: AssetImage(kid['avatar']),
                                                  radius: 40,
                                                  backgroundColor:
                                                      selectedName == kid['firstName'] && selectedRole == "kid"
                                                          ? Colors.blueAccent
                                                          : Colors.transparent,
                                                ),
                                              ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  kid['firstName'],
                                                  style: TextStyle(
                                                    fontSize: 16.7,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: GoogleFonts.fredoka().fontFamily,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),

                                      const Spacer(),

                                      // Login Button always at bottom of container
                                      Padding(
                                        padding: const EdgeInsets.only(top: 30.0),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (selectedName == null || selectedRole == null) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Please select a user above first")),
                                                );
                                                return;
                                              }

                                              if (selectedRole == 'parent') {
                                                // Navigate to Parent Login Page
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ParentLoginPage(),
                                                  ),
                                                );
                                              } else {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => KidsLoginPage(),
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              side: const BorderSide(color: Colors.black, width: 2),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              elevation: 2,
                                              shadowColor: Colors.grey.withAlpha(128),
                                            ).copyWith(
                                              elevation: WidgetStateProperty.resolveWith<double>((states) {
                                                if (states.contains(WidgetState.pressed)) return 12;
                                                if (states.contains(WidgetState.hovered)) return 8;
                                                return 2;
                                              }),
                                              shadowColor: WidgetStateProperty.resolveWith<Color>((states) {
                                                if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
                                                  return Colors.black.withAlpha(180);
                                                }
                                                return Colors.grey.withAlpha(128);
                                              }),
                                            ),
                                            child: Text(
                                              selectedName != null ? 'Log in as $selectedName' : 'Log in',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: GoogleFonts.fredoka().fontFamily,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Log out button
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            await FirebaseAuth.instance.signOut();
                                            if (!mounted) return;
                                            // ignore: use_build_context_synchronously
                                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WelcomePage()));
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.black,
                                            side: const BorderSide(color: Colors.black, width: 2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                          child: Text(
                                            'Log out',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: GoogleFonts.fredoka().fontFamily,
                                            ),
                                          ),
                                        ),
                                      ),

                                      
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          /// Owl image in front
          Positioned(
            top: 43,
            right: -25,
            child: Image.asset(
              'assets/owl.png',
              height: 150,
              width: 240,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

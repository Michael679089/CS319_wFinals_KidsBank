import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/pages/kids_login_page.dart';
import 'welcomepage.dart';
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
  String? selectedKidDocId;
  String? selectedAvatarPath;

  String parentName = '';
  String parentAvatar = '';
  String userId = '';
  List<QueryDocumentSnapshot<Map<String, dynamic>>> kidsDocs = [];

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
        kidsDocs = kidsSnapshot.docs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      onPopInvokedWithResult: (didPop, result) async {},
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
                                            selectedKidDocId = null; // clear kid selection
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
                                                backgroundColor:
                                                    selectedName == parentName && selectedRole == "parent"
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
                                        children: kidsDocs.map((kidDoc) {
                                          final kid = kidDoc.data();
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedName = kid['firstName'];
                                                selectedRole = "kid";
                                                selectedKidDocId = kidDoc.id;
                                                selectedAvatarPath = kid['avatar'];
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

                                      // Login Button always at bottom
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
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => const ParentLoginPage(),
                                                  ),
                                                );
                                              } else {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => KidsLoginPage(
                                                      kidDocId: selectedKidDocId!,
                                                      kidName: selectedName!,
                                                      avatarPath: selectedAvatarPath!,
                                                    ),
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
                                            Navigator.pushReplacement(
                                              // ignore: use_build_context_synchronously
                                              context,
                                              MaterialPageRoute(builder: (context) => const WelcomePage()),
                                            );
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

            /// Owl image
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

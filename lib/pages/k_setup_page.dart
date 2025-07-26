import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'login_page.dart';

class KidsSetupPage extends StatefulWidget {
  const KidsSetupPage({
    super.key,
    required parentId,
    required cameFromParentDashboard,
  });

  @override
  State<KidsSetupPage> createState() => _KidsSetupPageState();
}

class _KidsSetupPageState extends State<KidsSetupPage> {
  String parentName = '';
  String parentAvatar = '';
  String familyUserId = '';
  String parentId = '';

  bool _didUserCameFromParentDashboard = false;

  // INITSTATE Function:

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParentInfo();
    });
  }

  // Other Functions:

  Future<void> _loadParentInfo() async {
    final familyUser = FirebaseAuth.instance.currentUser;
    if (familyUser != null) {
      // Step 1: Try to get the Parent that got here name.
      final myModalRoute = ModalRoute.of(context);

      if (myModalRoute == null) {
        debugPrint("kidsSetupPage - ERROR: myModalRoute was null");
        return;
      }
      final args = myModalRoute.settings.arguments as Map<String, dynamic>;
      var newParentId = args["parent-id"] as String;

      // 1 - making sure user didn't came from dashboard if it was available
      try {
        _didUserCameFromParentDashboard =
            args["came-from-parent-dashboard"] as bool;
      } catch (e) {
        debugPrint("kidsSetupPage - parent didn't come from dashboard");
      }

      var parentCollection = FirebaseFirestore.instance.collection("parents");
      var parentDoc = await parentCollection.doc(newParentId).get();
      var lastName =
          "${parentDoc['lastName']?.toString().substring(0, 1).toUpperCase()}.";
      var newParentName = "${parentDoc['firstName']}, $lastName.";
      var newParentAvatar = parentDoc['avatarFilePath'];
      var newFamilyUserId = familyUser.uid;

      if (parentDoc.exists) {
        setState(() {
          parentName = newParentName;
          parentAvatar = newParentAvatar;
          familyUserId = newFamilyUserId;
          parentId = newParentId;
        });
      }
    }
  }

  Future<List<KidModel>> _loadKids() async {
    var myFirestoreService = FirestoreService();
    var myAuthService = AuthService();

    var familyId = myAuthService.getCurrentUser()?.uid as String;

    var kidsList = myFirestoreService.getKidsByFamilyUserId(familyId);

    return kidsList;
  }

  void addKid() async {
    var navigator = Navigator.of(context);

    navigator.pushNamed(
      '/create-kids-account-page',
      arguments: {
        "parent-id": parentId,
        "came-from-parent-dashboard": _didUserCameFromParentDashboard,
        "family-user-id": familyUserId,
      },
    );
    debugPrint(
      "kidsSetupPage - addKids BTN pressed, redirected to create-kids-account-page",
    );
  }

  //
  // BUILD FUNCTION
  //

  @override
  Widget build(BuildContext context) {
    var navigator = Navigator.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }

        if (_didUserCameFromParentDashboard) {
          navigator.pushReplacementNamed(
            "/parent-dashboard-page",
            arguments: {"family-user-id": familyUserId, "parent-id": parentId},
          );
          debugPrint(
            "kidsSetupPage - User that came from parent dashboard pressed back on phone - redirected to Parent-Dashbaord-Page",
          );
          return;
        }

        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log Out'),
            content: const Text(
              'Do you want to log out and return to the login page?',
            ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Parent Info Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: parentAvatar.isNotEmpty
                          ? AssetImage(parentAvatar)
                          : const AssetImage('assets/avatar1.png'),
                      radius: 50,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parentName.isNotEmpty ? parentName : "Parent",
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
                            fontWeight: FontWeight.w600,
                            fontFamily: GoogleFonts.fredoka().fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Set up kid’s account",
                  style: TextStyle(
                    fontSize: 28.8,
                    fontWeight: FontWeight.w700,
                    fontFamily: GoogleFonts.fredoka().fontFamily,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Kids List Container
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFefe6e8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: FutureBuilder<List<KidModel>>(
                      future: _loadKids(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final List<KidModel> kids =
                            snapshot.data as List<KidModel> ?? [];

                        return ListView(
                          children: [
                            ...kids.map((kid) => _buildKidTile(kid)),
                            const SizedBox(height: 12),

                            // "+" Add Kid Button - Where the Add Kid Logic is
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  addKid();
                                },
                                child: CircleAvatar(
                                  backgroundColor: const Color(0xFF4E88CF),
                                  radius: 30,
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Continue Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!_didUserCameFromParentDashboard) {
                        navigator.pushReplacementNamed(
                          "/account-selector-page",
                          arguments: {"family-user-id": familyUserId},
                        );
                        debugPrint(
                          "kidsSetupPage - user not from dashboard. user pressed continue. Redirected to account-selector-page",
                        );
                      } else {
                        navigator.pushReplacementNamed(
                          "/parent-dashboard-page",
                          arguments: {
                            "family-user-id": familyUserId,
                            "parent-id": parentId,
                          },
                        );
                        debugPrint(
                          "kidsSetupPage - user from dashboard. user pressed continue. Redirected to parent-dashboard-page",
                        );
                      }
                    },
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
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color randomizeColors() {
    final Random random = Random();

    // Hue: full range 0–360
    final double hue = random.nextDouble() * 360;

    // Saturation: 0.4–0.7 for mild colors
    final double saturation = 0.4 + random.nextDouble() * 0.3;

    // Lightness: 0.75–0.9 for pale colors
    final double lightness = 0.75 + random.nextDouble() * 0.15;

    final hslColor = HSLColor.fromAHSL(1.0, hue, saturation, lightness);
    return hslColor.toColor();
  }

  Widget _buildKidTile(KidModel kid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: randomizeColors(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(kid.avatar_file_path),
            radius: 26,
          ),
          const SizedBox(width: 12),
          Text(
            kid.first_name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: GoogleFonts.fredoka().fontFamily,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

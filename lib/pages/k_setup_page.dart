import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';
import 'login_page.dart';

class KidsSetupPage extends StatefulWidget {
  final bool cameFromParentDashboard;
  final String user_id;

  const KidsSetupPage({
    super.key,
    required this.cameFromParentDashboard,
    required this.user_id,
  });

  @override
  State<KidsSetupPage> createState() => _KidsSetupPageState();
}

class _KidsSetupPageState extends State<KidsSetupPage> {
  String parentName = '';
  String parentAvatar = '';
  String user_id = '';
  String parentId = '';

  // INITSTATE Function:

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParentInfo();
    });
  }

  //
  // Other Functions:
  //

  // loading information functions:
  Future<void> _loadParentInfo() async {
    debugPrint("KSetupPage - loadParentInfo Function START");

    // Step 1: Let's get the Parent-ID:
    user_id = widget.user_id;
    var family_id = await FirestoreService.fetch_family_id(user_id) as String;
    var parent_object = await FirestoreService.readParent(family_id);

    if (user_id.isNotEmpty && parent_object != null) {
      final lastName = (parent_object.last_name).isNotEmpty
          ? '${parent_object.last_name[0].toUpperCase()}${parent_object.last_name.substring(1).toLowerCase()}'
          : '';

      final firstInitial = (parent_object.first_name).isNotEmpty
          ? '${parent_object.first_name[0].toUpperCase()}.'
          : '';

      final displayName =
          '$lastName${lastName.isNotEmpty && firstInitial.isNotEmpty ? ', ' : ''}$firstInitial';

      debugPrint('Formatted name: $displayName');

      setState(() {
        parentName = displayName;
        parentAvatar = parent_object.avatar_file_path;
        parentId = parent_object.id?.toString() ?? '';
      });
    }
  }

  Future<List<KidModel>> _loadKids() async {
    var user = AuthService.getCurrentUser();
    if (user != null) {
      var user_id = user.uid;
      var family_object = await FirestoreService.readFamily(user_id);
      var family_id = family_object?.id;

      var kidsList = FirestoreService.fetch_all_kids_by_family_id(family_id!);

      return kidsList;
    } else {
      return [];
    }
  }

  // -----

  void _handleContinueButton() async {
    debugPrint("KSetupPage - _handleContinueButton START");
    debugPrint("KSetupPage - continue button was pressed");

    // Step 1: transfer back the user to parent dashboard if user came from parent dashboard,
    // otherwise send user back to account selector page.
    debugPrint(
      "KSetupPage - did user came from dashboard? ${widget.cameFromParentDashboard}",
    );
    if (widget.cameFromParentDashboard == true) {
      Navigator.of(context).pushReplacementNamed(
        "/parent-dashboard-page",
        arguments: {"user-id": user_id, "parent-id": parentId},
      );
      debugPrint(
        "kidsSetupPage - user from dashboard. user pressed continue. Redirected to parent-dashboard-page",
      );
    } else {
      Navigator.of(context).pushReplacementNamed(
        "/account-selector-page",
        arguments: {"user-id": user_id, 'there-are-parent-in-family': true},
      );
      debugPrint(
        "kidsSetupPage - user not from dashboard. user pressed continue. Redirected to account-selector-page",
      );
    }
  }

  void _handleAddKidFunction() async {
    debugPrint("KSetupPage - _handleAddKidFunction START");
    debugPrint("KSetupPage - add kid button was pressed");
    var navigator = Navigator.of(context);
    var user = AuthService.getCurrentUser();

    if (user != null) {
      debugPrint(
        "KSetupPage - addKids BTN pressed, redirected to create-kids-account-page",
      );
      debugPrint("KSetupPage - what's the parent id: $parentId");
      navigator.pushNamed(
        '/create-kids-account-page',
        arguments: {
          "parent-id": parentId,
          "came-from-parent-dashboard": widget.cameFromParentDashboard,
          "user-id": user.uid,
        },
      );
    }
    debugPrint("KSetupPage - _handleAddKidFunction END");
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

        if (widget.cameFromParentDashboard) {
          navigator.pushReplacementNamed(
            "/parent-dashboard-page",
            arguments: {
              "user-id": widget.user_id, "parent-id": parentId
              },
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
                  await AuthService.logoutAccount();
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
                            snapshot.data as List<KidModel>;

                        return ListView(
                          children: [
                            ...kids.map((kid) => _buildKidTile(kid)),
                            const SizedBox(height: 12),

                            // The Add Kid Button + + +
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  _handleAddKidFunction();
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
                      _handleContinueButton();
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

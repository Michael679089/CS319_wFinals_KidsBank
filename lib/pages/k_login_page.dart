import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';

class KidsLoginPage extends StatefulWidget {
  const KidsLoginPage({super.key});

  @override
  State<KidsLoginPage> createState() => _KidsLoginPageState();
}

class _KidsLoginPageState extends State<KidsLoginPage> {
  final TextEditingController pincodeController = TextEditingController();

  // Saved Credentials
  String familyUserId = '';
  String kidId = '';
  String avatarFilePath = '';
  String kidFirstName = '';

  // My Services
  var myAuthService = AuthService();
  var myFirestoreService = FirestoreService();

  //
  // INITSTATE Function:
  //
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // Other Functions

  void _loadData() async {
    // Step 1: Get Family User UID;
    var familyUser = myAuthService.getCurrentUser();
    if (familyUser == null) return;
    familyUserId = familyUser.uid;

    // Step 2: Get the kids Docs;
    final myModalRoute = ModalRoute.of(context);
    if (myModalRoute == null) {
      debugPrint("kidsSetupPage - ERROR: myModalRoute was null");
      return;
    }
    final args = myModalRoute.settings.arguments as Map<String, dynamic>;
    debugPrint("What's in the args?: ${args.toString()}");
    var newKidId = args["kidDocId"] as String;
    var newAvatarPath = args["avatarPath"] as String;
    var newKidFirstName = await myFirestoreService.getKidFirstName(newKidId);

    setState(() {
      kidId = newKidId;
      avatarFilePath = newAvatarPath;
      kidFirstName = newKidFirstName;
    });

    debugPrint("kidsLoginPage - loadData success");
  }

  @override
  Widget build(BuildContext context) {
    var navigator = Navigator.of(context);

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
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.3 * 255).toInt()),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(10, 12),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundImage: AssetImage(avatarFilePath),
                        radius: 70,
                        backgroundColor: const Color(0xFF4E88CF),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Hi $kidFirstName!",
                      style: GoogleFonts.fredoka(
                        fontSize: 58.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel("Please input your pincode"),
                    const SizedBox(height: 8),
                    _buildPasswordField(pincodeController),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFCA26),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
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

                        // Back Button
                        ElevatedButton.icon(
                          onPressed: () {
                            debugPrint(
                              "kidsLoginPage - going back to account Selector Page",
                            );
                            navigator.pushReplacementNamed(
                              "/account-selector-page",
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
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

  void _login() async {
    var navigator = Navigator.of(context);

    debugPrint("kidsLoginPage - Login called");
    final pincode = pincodeController.text.trim();

    if (pincode.isEmpty) {
      _showSnackbar("Password cannot be empty.");
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('kids')
          .doc(kidId)
          .get();

      // Just for legacy accounts I want them to use pincode later.
      try {
        if (doc["password"] != pincode) {
          debugPrint("kidsLoginPage - incorrect pincode");
          return;
        }
      } catch (e) {
        debugPrint("kidsLoginPage - password doesn't exist. Try pincode");
      }

      try {
        if (doc["pincode"] != pincode) {
          debugPrint("kidsLoginPage - incorrect pincode");
          return;
        }
      } catch (e) {
        debugPrint("kidsLoginPage - pincode doesn't exist. error");
        throw Error();
      }

      _showSnackbar("Login successful!", isError: false);

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      //Navigate and pass kidId to KidsDashboard
      debugPrint(
        "kidsLoginPage - login sucess, redirecting to kids-dashboard-page.",
      );
      navigator.pushReplacementNamed(
        "/kids-dashboard-page",
        arguments: {"kid-id": kidId, "family-user-id": familyUserId},
      );
    } catch (e) {
      _showSnackbar("Error: ${e.toString()}");
    }
  }

  void _showSnackbar(String message, {bool isError = true}) {
    final snackBar = SnackBar(
      content: Text(message, style: GoogleFonts.fredoka(color: Colors.white)),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackBar);
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

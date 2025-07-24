import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ParentLoginPage extends StatefulWidget {
  const ParentLoginPage({super.key});

  @override
  State<ParentLoginPage> createState() => _ParentLoginPageState();
}

class _ParentLoginPageState extends State<ParentLoginPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cardController = TextEditingController();

  // Saved Credentials
  String parentId = '';
  String parentName = '';
  String avatarPath = '';
  String familyUserId = '';
  String familyName = '';

  // INITSTATE FUNCTION
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParentData();
    });
  }

  Future<void> _loadParentData() async {
    // Step 1: Get Parent Name, Avatar Path, and User Id
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final myModalRoute = ModalRoute.of(context);
    if (myModalRoute == null) {
      return;
    }
    final args = myModalRoute.settings.arguments as Map<String, String?>;
    setState(() {
      parentId = args['parent-id'] as String;
      parentName = args["name"] as String;
      avatarPath = args["avatar"] as String;
      familyName = args["family-name"] as String;
      familyUserId = user.uid;
    });

    debugPrint(
      "parentLoginPage - successfully loaded the data - parentID: $parentId",
    );
  }

  Future<void> _login() async {
    // The Login Function
    final pincode = passwordController.text.trim();
    final cardDigits = cardController.text.trim();
    var navigator = Navigator.of(context);

    // Step 1: Cleaning the input
    if (pincode.isEmpty) {
      _showSnackbar("Password cannot be empty.");
      return;
    }

    if (cardDigits.length != 4 || int.tryParse(cardDigits) == null) {
      _showSnackbar("Card digits must be 4 numbers.");
      return;
    }

    // Step 2: Password Input Done - Now Get the real passcode from Firestore and Verify it.
    try {
      final parentCollection = FirebaseFirestore.instance.collection("parents");
      final parentDoc = await parentCollection.doc(parentId).get();

      if (parentDoc['pincode'] != pincode) {
        _showSnackbar("Incorrect password.");
        debugPrint("parentLoginPage - ERROR: User input Wrong Password.");
        return;
      }

      // Step 3: Now for card digits verify if correct.
      final familyPaymentCollection = FirebaseFirestore.instance.collection(
        "family_payment_info",
      );
      final familyPaymentSnapshot = await familyPaymentCollection
          .where("user_id", isEqualTo: familyUserId)
          .get();
      final familyPaymentDoc = familyPaymentSnapshot.docs.first;
      var cardNumber = familyPaymentDoc["card_number"].toString();

      if (cardNumber.length >= 4) {
        if (cardNumber.endsWith(cardDigits)) {
          debugPrint("parentLoginPage - Card Digits Verified");
        }
      } else {
        debugPrint(
          "parentLoginPage - ERROR: cardNumber isn't more than 4 numbers",
        );
        _showSnackbar("Card not found.");
        return;
      }

      // Step 4: CardDigits is verified, user can proceed to Parent Dashboard Page.
      _showSnackbar("Login successful!", isError: false);

      debugPrint(
        "parentLoginPage - Parent Login Successful. Redirecting to Parent-Dashboard-Page",
      );
      navigator.pushReplacementNamed(
        '/parent-dashboard-page',
        arguments: {
          "family-name": familyName,
          "family-user-id": familyUserId,
          "parent-id": parentId,
        },
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

  // BUILD

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
                      parentName.isNotEmpty ? "Hi $parentName!" : "Hi!",
                      style: GoogleFonts.fredoka(
                        fontSize: 58.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel(
                      "Please input this parent's sub-account pincode",
                    ),
                    const SizedBox(height: 8),
                    _buildPincodeField(passwordController),

                    const SizedBox(height: 20),
                    _buildLabel("Last 4 digits of linked card"),
                    const SizedBox(height: 8),
                    _buildCardField(cardController),

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
                        // The Back BUTTON
                        ElevatedButton.icon(
                          onPressed: () {
                            navigator.pushReplacementNamed(
                              "/account-selector-page",
                              arguments: {
                                "family-name": familyName,
                                "family-user-id": familyUserId,
                              },
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

  // My Widgets For Build

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

  Widget _buildPincodeField(TextEditingController controller) {
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
        keyboardType: TextInputType.number,
        style: GoogleFonts.fredoka(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCardField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
        obscuringCharacter: '•',
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

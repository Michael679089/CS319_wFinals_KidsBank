import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/family_payment_info_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class ParentLoginPage extends StatefulWidget {
  final String parent_id;
  final String user_id;

  const ParentLoginPage({super.key, required this.parent_id, required this.user_id});

  @override
  State<ParentLoginPage> createState() => _ParentLoginPageState();
}

class _ParentLoginPageState extends State<ParentLoginPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cardController = TextEditingController();

  // Saved Credentials
  String parentName = '';
  String avatarPath = '';
  String user_id = '';
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

    user_id = widget.user_id;

    ParentModel? newParentModel = await FirestoreService.fetch_parent_by_parent_id(widget.parent_id);
    var newFamilyName = await FirestoreService.fetch_family_name(user_id);

    if (newParentModel != null && newFamilyName.isNotEmpty) {
      setState(() {
        parentName = newParentModel.first_name;
        avatarPath = newParentModel.avatar_file_path;
        familyName = newFamilyName;
      });
    } else {
      debugPrint("PLoginPage - wrong parent_id = ${widget.parent_id}");
    }

    debugPrint("parentLoginPage - successfully loaded the data - parentID: ${widget.parent_id}");
  }

  Future<void> _handleLogin() async {
    debugPrint("parentLoginPage - attempt to login");

    // The Login Function
    final pincode = passwordController.text.trim();
    final cardDigits = cardController.text.trim();
    var navigator = Navigator.of(context);

    // Step 1: Cleaning the input
    if (pincode.isEmpty) {
      UtilityTopSnackBar.show(message: "Password cannot be empty.", context: context, isError: true);
      return;
    }

    if (cardDigits.length != 4 || int.tryParse(cardDigits) == null) {
      UtilityTopSnackBar.show(message: "Card digits must be 4 numbers.", context: context, isError: true);
      return;
    }

    // Step 2: Password Input Done - Now Get the real passcode from Firestore and Verify it.
    try {
      final parentCollection = FirebaseFirestore.instance.collection("parents");
      final parentDoc = await parentCollection.doc(widget.parent_id).get();

      if (parentDoc['pincode'] != pincode) {
        UtilityTopSnackBar.show(message: "Incorrect password.", context: context, isError: true);
        debugPrint("parentLoginPage - ERROR: User input Wrong Password.");
        return;
      }

      // Step 3: Now for card digits verify if correct.
      user_id = widget.user_id;
      debugPrint(user_id);
      FamilyPaymentInfoModel? familyPaymentDoc = await FirestoreService.readFamilyPaymentInfo(user_id);

      if (familyPaymentDoc != null) {
        var cardNumber = familyPaymentDoc.card_number;

        if (cardNumber.length >= 4) {
          if (cardNumber.endsWith(cardDigits)) {
            debugPrint("parentLoginPage - Card Digits Verified");
          }
        } else {
          debugPrint("parentLoginPage - ERROR: cardNumber isn't more than 4 numbers");
          UtilityTopSnackBar.show(message: "Card not found.", context: context, isError: true);
          return;
        }
      } else {
        debugPrint("PLoginPage - family payment info was found null. Throwing Error");
        throw Error;
      }

      // Step 4: CardDigits is verified, user can proceed to Parent Dashboard Page.
      UtilityTopSnackBar.show(message: "Login successful!", context: context, isError: false);

      // Step 5: Hold on, let's check if there's kids.
      var family_id = await FirestoreService.fetch_family_id(user_id);
      List<KidModel> kidsList = await FirestoreService.fetch_all_kids_by_family_id(family_id!);
      if (kidsList.isEmpty) {
        if (mounted) {
          UtilityTopSnackBar.show(
            message: "Hold on, you can't go to parent dashboard just yet, you need to have at least one kid account",
            context: context,
            isError: true,
          );
        }
        navigator.pushNamed(
          "/create-kids-account-page",
          arguments: {"parent-id": widget.parent_id, "user-id": widget.user_id, "came-from-parent-dashboard": false},
        );
      } else {
        debugPrint("parentLoginPage - Parent Login Successful. Redirecting to Parent-Dashboard-Page $user_id");
        navigator.pushReplacementNamed('/parent-dashboard-page', arguments: {"family-name": familyName, "user-id": user_id, "parent-id": widget.parent_id, "family_id": family_id,});
      }
    } catch (e) {
      UtilityTopSnackBar.show(message: "Error checking pincode == password: ${e.toString()}", context: context, isError: true);
    }
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
                          BoxShadow(color: Colors.black.withAlpha((0.3 * 255).toInt()), spreadRadius: 1, blurRadius: 10, offset: const Offset(10, 12)),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundImage: avatarPath.isNotEmpty ? AssetImage(avatarPath) : const AssetImage('assets/avatar1.png'),
                        radius: 70,
                        backgroundColor: const Color(0xFF4E88CF),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      parentName.isNotEmpty ? "Hi $parentName!" : "Hi!",
                      style: GoogleFonts.fredoka(fontSize: 58.2, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel("Please input this parent's sub-account pincode"),
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
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFCA26),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.black, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(
                              'Log in',
                              style: GoogleFonts.fredoka(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // The Back BUTTON
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          label: Text(
                            "Back",
                            style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
        style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
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
        style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
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
        style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
        decoration: const InputDecoration(counterText: "", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      ),
    );
  }
}
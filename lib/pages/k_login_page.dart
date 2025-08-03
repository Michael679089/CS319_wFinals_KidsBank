import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class KidsLoginPage extends StatefulWidget {
final String user_id;
final String kid_id;

  const KidsLoginPage({
    super.key,
    required this.user_id,
    required this.kid_id,
  });

  @override
  State<KidsLoginPage> createState() => _KidsLoginPageState();
}

class _KidsLoginPageState extends State<KidsLoginPage> {
  final TextEditingController pincodeController = TextEditingController();
  bool isLoading = false;
  bool hasError = false;

  String kidName = "";
  String kidAvatar = "";

  @override
  void initState() {
    super.initState();
    _fetchKidData();
  }

  Future<void> _fetchKidData() async {
  debugPrint("KidsLoginPage - Fetching data for kid_id: ${widget.kid_id}");
  try {
    final kidDoc = await FirebaseFirestore.instance
        .collection('kids')
        .doc(widget.kid_id)
        .get();

    if (kidDoc.exists) {
      final data = kidDoc.data()!;
      debugPrint("Firestore kid data: $data");

      setState(() {
        kidName = data['first_name'] ?? '';
        kidAvatar = data['avatar_file_path'] ?? 'assets/default_avatar.png';
      });
    } else {
      UtilityTopSnackBar.show(
        context: context,
        message: "Kid account not found",
        isError: true,
      );
    }
  } catch (e) {
    debugPrint("KidsLoginPage - ERROR fetching kid: $e");
  }
}
  Future<void> _login() async {
    if (widget.kid_id.isEmpty) {
      UtilityTopSnackBar.show(
        context: context,
        message: "Error: No kid account selected",
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    final pincode = pincodeController.text.trim();
    if (pincode.isEmpty) {
      UtilityTopSnackBar.show(
        context: context,
        message: "Pincode cannot be empty",
        isError: true,
      );
      setState(() => isLoading = false);
      return;
    }

    try {
      final kidDoc = await FirebaseFirestore.instance
          .collection('kids')
          .doc(widget.kid_id)
          .get();

      if (!kidDoc.exists) {
        UtilityTopSnackBar.show(
          context: context,
          message: "Kid account not found",
          isError: true,
        );
        setState(() => isLoading = false);
        return;
      }

      final kidData = kidDoc.data();
      if (kidData == null || kidData['pincode'] != pincode) {
        UtilityTopSnackBar.show(
          context: context,
          message: "Incorrect pincode",
          isError: true,
        );
        setState(() => isLoading = false);
        return;
      }

      UtilityTopSnackBar.show(
        context: context,
        message: "Login successful!",
        isError: false,
      );
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        "/kids-dashboard-page",
        arguments: {
          "kid-id": widget.kid_id,
          "family-user-id": widget.user_id,
          "there-are-parent-in-family": false, // Assuming no parents for kids login
        },
      );
    } catch (e) {
      UtilityTopSnackBar.show(
        context: context,
        message: "Error: ${e.toString()}",
        isError: true,
      );
      debugPrint("Login error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    CircleAvatar(
                      backgroundImage: AssetImage(
                        kidAvatar.isNotEmpty ? kidAvatar : 'assets/default_avatar.png',
                      ),
                      radius: 70,
                      backgroundColor: const Color(0xFF4E88CF),
                    ),
                    const SizedBox(height: 12),

                    // Greeting
                    Text(
                      "Hi ${kidName.isNotEmpty ? kidName : '...'}!",
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

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
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
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Text(
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
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
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

  // Original Helper Widgets
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
        keyboardType: TextInputType.number,
        maxLength: 4,
        style: GoogleFonts.fredoka(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: "Enter 4-digit pincode",
        ),
      ),
    );
  }

  @override
  void dispose() {
    pincodeController.dispose();
    super.dispose();
  }
}
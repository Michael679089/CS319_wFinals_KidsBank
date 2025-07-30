import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_payment_info_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class CreateKidAccountPage extends StatefulWidget {
  final dynamic user_id;

  final dynamic parentId;

  const CreateKidAccountPage({
    super.key,
    required this.user_id,
    required this.parentId,
  });

  @override
  State<CreateKidAccountPage> createState() => _CreateKidAccountPageState();
}

class _CreateKidAccountPageState extends State<CreateKidAccountPage> {
  String selectedAvatar = 'assets/avatar1.png';
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController phoneNumController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();

  FirestoreService myFirestoreService = FirestoreService();

  // Saved Credentials
  String parentId = '';
  bool _didUserCameFromParentDashboard = false;

  // INIT STATE FUNCTION
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

      setState(() {
        parentId = newParentId;
        _didUserCameFromParentDashboard =
            args["came-from-parent-dashboard"] as bool;
      });
    }

    debugPrint("createKidsAccountPage - succesfully load parent info");
  }

  void _showAvatarPicker() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: [
                for (var i = 1; i <= 6; i++)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAvatar = 'assets/avatar$i.png';
                      });
                      Navigator.of(context).pop();
                    },
                    child: CircleAvatar(
                      backgroundImage: AssetImage('assets/avatar$i.png'),
                      radius: 30,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2015),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4E88CF),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    final overlay = Overlay.of(context);
    final color = isError ? Colors.red : Colors.green;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewInsets.top + 40,
        left: 20,
        right: 20,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontFamily: GoogleFonts.fredoka().fontFamily,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> _submit() async {
    final name = firstNameController.text.trim();
    final dob = dateOfBirthController.text.trim();
    final phone = phoneNumController.text.trim();
    final password = pincodeController.text;

    var navigator = Navigator.of(context);

    if (name.isEmpty || dob.isEmpty || phone.isEmpty || password.isEmpty) {
      _showSnackbar('All fields are required', isError: true);
      return;
    }

    final user = AuthService.getCurrentUser();
    if (user == null) {
      _showSnackbar('User not authenticated', isError: true);
      return;
    }

    String? kidId;

    // Step 1: Adding kids to kids collection. Try-Catch
    try {
      var firstName = firstNameController.text;
      var lastName = lastNameController.text;
      var dateOfBirth = DateTime.parse(
        dateOfBirthController.text,
      ); // year-month-day 2015-01-28
      var phoneNumber = phoneNumController.text;
      var pincode = pincodeController.text;
      var avatar = selectedAvatar;
      var familyUserId = user.uid;

      KidModel newKidModel = KidModel(
        first_name: firstName,
        last_name: lastName,
        date_of_birth: dateOfBirth,
        pincode: pincode,
        avatar_file_path: avatar,
        family_id: familyUserId,
        created_at: DateTime.now(),
      );
      kidId = await FirestoreService.createKid(newKidModel);

      if (kidId != null) {
        Utility_TopSnackBar.show(
          message: 'Kid account created successfully!',
          context: context,
        );
        debugPrint(
          "createKidsAccountPage - succesfully created kid, moving to creating kids_payment_info",
        );

        // Step 2: Let's now add the kids payment info for this child
        try {
          var phoneNumber = phoneNumController.text;
          var family_object = await FirestoreService.readFamily(widget.user_id);
          var family_id = family_object?.id as String;
          KidsPaymentInfoModel newKidPaymentInfoModel = KidsPaymentInfoModel(
            kid_id: kidId,
            phone_number: phoneNumber,
            total_amount_left: 0,
            family_id: family_id,
          );
          FirestoreService.createKidPaymentInfo(newKidPaymentInfoModel);
          Utility_TopSnackBar.show(
            message: 'Kid Payment Info created successfully!',
            context: context,
          );
          debugPrint(
            "createKidsAccountPage - succesfully created kid payment info.",
          );
        } catch (e) {
          debugPrint("$e");
          return;
        }

        debugPrint(
          "createKidsAccountPage - successfully creating a kid and a kidpaymentinfo",
        );

        navigator.pushReplacementNamed(
          "/kids-setup-page",
          arguments: {
            "parent-id": parentId,
            "came-from-parent-dashboard": _didUserCameFromParentDashboard,
          },
        );
      } else {
        debugPrint("ERROR: kid id is null");
      }
    } catch (e) {
      _showSnackbar('Error saving data: $e', isError: true);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFCA26),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(selectedAvatar),
                    radius: 60,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.purple,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Title - Set up Kids Account
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Set Up Kid’s Account',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      fontFamily: GoogleFonts.fredoka().fontFamily,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F1F1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Column(
                  children: [
                    _buildLabel('First Name'),
                    _buildField(firstNameController),
                    _buildLabel('Last Name'),
                    _buildField(lastNameController),
                    const SizedBox(height: 20),
                    _buildLabel('Date of birth'),
                    _buildField(
                      dateOfBirthController,
                      onTap: _pickDate,
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Phone Number #(ex: +63)'),
                    _buildField(
                      phoneNumController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Password'),
                    _buildField(pincodeController, obscure: true),

                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: Utilities().ourButtonStyle1(),
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: GoogleFonts.fredoka().fontFamily,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: GoogleFonts.fredoka().fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller, {
    bool obscure = false,
    bool readOnly = false,
    int? maxLength,
    TextInputType? keyboardType,
    void Function()? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFAEDDFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        maxLength: maxLength,
        keyboardType: keyboardType,
        onTap: onTap,
        obscuringCharacter: '*',
        style: TextStyle(
          fontFamily: GoogleFonts.fredoka().fontFamily,
          fontSize: 24,
        ),
        decoration: const InputDecoration(
          counterText: "",
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

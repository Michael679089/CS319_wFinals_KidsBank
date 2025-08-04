import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_payment_info_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';
import 'package:flutter/services.dart';
import 'package:wfinals_kidsbank/utilities/Enum_For_Avatar_Images.dart';

class CreateKidAccountPage extends StatefulWidget {
  final String user_id;
  final String parent_id;
  final bool didUserCameFromDashboard;

  const CreateKidAccountPage({super.key, required this.user_id, required this.parent_id, required this.didUserCameFromDashboard});

  @override
  State<CreateKidAccountPage> createState() => _CreateKidAccountPageState();
}

class PhonePrefixFormatter extends TextInputFormatter {
  final String prefix;
  final int maxDigits;

  PhonePrefixFormatter({required this.prefix, required this.maxDigits});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Always keep the prefix at the start
    if (!newValue.text.startsWith(prefix)) {
      return oldValue;
    }

    // Extract digits after prefix
    final digitsAfterPrefix = newValue.text.substring(prefix.length);

    // Allow only numbers after prefix
    final onlyNumbers = digitsAfterPrefix.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to maxDigits
    final limitedNumbers = onlyNumbers.length > maxDigits ? onlyNumbers.substring(0, maxDigits) : onlyNumbers;

    // Build final text
    final finalText = prefix + limitedNumbers;

    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: finalText.length),
    );
  }
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

  @override
  void initState() {
    super.initState();
    phoneNumController.text = "+639"; // Default phone number format
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParentInfo();
    });
  }

  Future<void> _loadParentInfo() async {
    final user = AuthService.getCurrentUser();
    if (user != null) {
      final myModalRoute = ModalRoute.of(context);
      if (myModalRoute == null) {
        debugPrint("kidsSetupPage - ERROR: myModalRoute was null");
        return;
      }
      var newParentId = widget.parent_id;

      var familyData = await FirestoreService.readFamily(widget.user_id);
      var familyLastName = familyData?.family_name ?? "";

      setState(() {
        parentId = newParentId;
        _didUserCameFromParentDashboard = widget.didUserCameFromDashboard;
        lastNameController.text = familyLastName;
      });
    }
    debugPrint("createKidsAccountPage - successfully load parent info");
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
                for (var avatar in AvatarImages.values)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAvatar = avatar.filePath;
                      });
                      Navigator.of(context).pop();
                    },
                    child: CircleAvatar(backgroundImage: AssetImage(avatar.filePath), radius: 30),
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
          colorScheme: const ColorScheme.light(primary: Color(0xFF4E88CF), onPrimary: Colors.white, onSurface: Colors.black),
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
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Text(
              message,
              style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily, color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
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

  Future<void> _handleSubmit() async {
    final name = firstNameController.text.trim();
    final dob = dateOfBirthController.text.trim();
    final phone = phoneNumController.text.trim();
    final pincode = pincodeController.text;

    var navigator = Navigator.of(context);

    if (name.isEmpty || dob.isEmpty || phone.isEmpty || pincode.isEmpty) {
      _showSnackbar('All fields are required', isError: true);
      return;
    }

    if (pincode.length != 4) {
      _showSnackbar('Pincode must be 4 digits', isError: true);
      return;
    }

    final user = AuthService.getCurrentUser();
    if (user == null) {
      _showSnackbar('User not authenticated', isError: true);
      return;
    }

    String? kidId;

    try {
      var firstName = firstNameController.text;
      var lastName = lastNameController.text;
      var dateOfBirth = DateTime.parse(dateOfBirthController.text);
      var avatar = selectedAvatar;
      var user_id = AuthService.getCurrentUser()!.uid;
      var family_id = await FirestoreService.fetch_family_id(user_id) as String;

      KidModel newKidModel = KidModel(
        family_id: family_id,
        first_name: firstName,
        last_name: lastName,
        date_of_birth: dateOfBirth,
        pincode: pincode, // Now using pincode instead of password
        avatar_file_path: avatar,
      );
      kidId = await FirestoreService.createKid(newKidModel);

      if (kidId != null) {
        UtilityTopSnackBar.show(message: 'Kid account created successfully!', context: context);

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
          var str = await FirestoreService.createKidPaymentInfo(newKidPaymentInfoModel);
          if (str.isEmpty) {
            debugPrint("CreateKidsAccountPage - str is empty");
            throw Error;
          }

          UtilityTopSnackBar.show(message: 'Kid Payment Info created successfully!', context: context);
        } catch (e) {
          debugPrint("$e");
          return;
        }

        navigator.pushReplacementNamed(
          "/kids-setup-page",
          arguments: {"user-id": user.uid, "family-id": family_id, "parent-id": parentId, "came-from-parent-dashboard": _didUserCameFromParentDashboard},
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
                  CircleAvatar(backgroundImage: AssetImage(selectedAvatar), radius: 60),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.purple),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Set Up Kid's Account",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, fontFamily: GoogleFonts.fredoka().fontFamily),
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
                    _buildField(dateOfBirthController, onTap: _pickDate, readOnly: true),
                    const SizedBox(height: 20),
                    _buildLabel('Phone Number #(ex: +63)'),
                    _buildField(
                      phoneNumController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PhonePrefixFormatter(prefix: "+639", maxDigits: 9)],
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('4-Digit Pincode'), // Changed label
                    _buildField(
                      pincodeController,
                      obscure: true,
                      maxLength: 4, // Limit to 4 digits
                      keyboardType: TextInputType.number, // Number keyboard
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: Utilities.ourButtonStyle1(),
                        child: Text(
                          'Create Account',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: GoogleFonts.fredoka().fontFamily, color: Colors.black),
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
        style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily, fontWeight: FontWeight.w700, fontSize: 20),
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
    List<TextInputFormatter>? inputFormatters,
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
        inputFormatters: inputFormatters,
        onTap: onTap,
        obscuringCharacter: '*',
        style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily, fontSize: 24),
        decoration: const InputDecoration(counterText: "", contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: InputBorder.none),
      ),
    );
  }
}

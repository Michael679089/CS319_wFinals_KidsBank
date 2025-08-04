import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';
import 'package:wfinals_kidsbank/utilities/Enum_For_Avatar_Images.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class ParentSetupPage extends StatefulWidget {
  final bool first_time_user;
  const ParentSetupPage({super.key, required this.first_time_user});

  @override
  State<ParentSetupPage> createState() => _ParentSetupPageState();
}

class _ParentSetupPageState extends State<ParentSetupPage> {
  // TextEditingController Variables
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();

  String selectedAvatar = 'assets/avatar1.png';
  OverlayEntry? _overlayEntry;
  bool _isSubmitting = false;

  // My Services
  FirestoreService myFirestoreAPI = FirestoreService();
  AuthService myAuthService = AuthService();

  String? user_id = '';

  // FUNCTIONS

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
              children: AvatarImages.values.map((avatar) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAvatar = avatar.filePath;
                    });
                    Navigator.of(context).pop();
                  },
                  child: CircleAvatar(backgroundImage: AssetImage(avatar.filePath), radius: 30),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    var navigator = Navigator.of(context);

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    // Step 1: Setting the inputs, then validating the inputs
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    DateTime? birthdate;
    try {
      birthdate = DateTime.parse(dateOfBirthController.text.trim());
    } catch (e) {
      birthdate = null;
    }
    final pincode = pincodeController.text.trim();

    // 1: Validate inputs
    if (firstName.isEmpty) {
      UtilityTopSnackBar.show(message: 'First name is required', context: context, isError: true);
      setState(() {
        _isSubmitting = false;
      });
      return;
    }
    if (lastName.isEmpty) {
      UtilityTopSnackBar.show(message: 'Last name is required', context: context, isError: true);
      setState(() {
        _isSubmitting = false;
      });
      return;
    }
    if (birthdate == null) {
      UtilityTopSnackBar.show(message: 'Date of birth is required', context: context, isError: true);
      setState(() {
        _isSubmitting = false;
      });
      return;
    }
    if (pincode.isEmpty || pincode.length < 4) {
      UtilityTopSnackBar.show(message: 'Pincode must be at least 4 digits', context: context, isError: true);
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    // Step 2: Reached here = user has validated inputs.
    // Continue to add new parent.

    try {
      final user = AuthService.getCurrentUser();
      if (user == null) {
        UtilityTopSnackBar.show(message: 'User not authenticated', context: context, isError: true);
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      user_id = AuthService.getCurrentUser()?.uid;
      var family_object = await FirestoreService.readFamily(user_id as String);
      if (family_object != null) {
        var family_id = family_object.id as String;

        final newParent = ParentModel(
          family_id: family_id,
          first_name: firstName,
          last_name: lastName,
          pincode: pincode,
          avatar_file_path: selectedAvatar,
          date_of_birth: birthdate,
          created_at: DateTime.now(),
        );
        var parentId = await FirestoreService.createParent(newParent);
        UtilityTopSnackBar.show(message: 'Parent added successfully', context: context, isError: false);
        navigator.pushNamed('/kids-setup-page', arguments: {"user-id": user_id, "parent-id": parentId, "came-from-parent-dashboard": false, "family_id": family_id});
      }
    } catch (e) {
      debugPrint("parentSetupPage - failed to add a parent: $e");
      if (mounted) {
        UtilityTopSnackBar.show(message: 'Failed to add parent: $e', context: context, isError: true);
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      debugPrint("parentSetupPage - submit function END");
    }
  }

  void _removeAllOverlays() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSnackbar(String message, {required bool isError}) {
    final overlay = Overlay.of(context);
    final color = isError ? Colors.red : Colors.green;

    _removeAllOverlays();

    _overlayEntry = OverlayEntry(
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

    overlay.insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 3), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1980),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF4E88CF), onPrimary: Colors.white, onSurface: Colors.black),
          textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFF4E88CF))),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dateOfBirthController.dispose();
    pincodeController.dispose();
    _removeAllOverlays();
    super.dispose();
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
        style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily, fontSize: 24),
        decoration: const InputDecoration(counterText: "", contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: InputBorder.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var top_title_text = 'Set up your parent account';
    if (widget.first_time_user) {
      top_title_text = "Set up your first parent account";
    }

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
              // Top-Title-Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20), // X: 20, Y: 0
                child: Center(
                  child: Text(
                    top_title_text,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: GoogleFonts.fredoka().fontFamily),
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
                    const SizedBox(height: 20),
                    _buildLabel('Last Name'),
                    _buildField(lastNameController),
                    const SizedBox(height: 20),
                    _buildLabel('Date of Birth'),
                    _buildField(dateOfBirthController, onTap: _pickDate, readOnly: true),
                    const SizedBox(height: 20),
                    _buildLabel('Pincode'),
                    _buildField(pincodeController, obscure: true, keyboardType: TextInputType.number, maxLength: 6),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4E88CF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.black, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : Text(
                                'Continue',
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
}

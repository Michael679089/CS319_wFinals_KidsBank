import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/family_model.dart';
import 'package:wfinals_kidsbank/database/models/family_payment_info_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';
import 'login_page.dart';

class RegisterAccountPage extends StatefulWidget {
  final bool is_broken_register;

  const RegisterAccountPage({super.key, required this.is_broken_register});

  @override
  State<RegisterAccountPage> createState() => _RegisterAccountPageState();
}

class _RegisterAccountPageState extends State<RegisterAccountPage> {
  // The TextEditingControllers Variables
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expController = TextEditingController();
  final TextEditingController _ccvController = TextEditingController();
  final bool is_register_debug_prefiled = false;

  // My Services
  FirestoreService myFirestoreAPI = FirestoreService();

  // Form Variables
  bool _obscurePassword = true;
  static const bool _obscureCcv = false;
  bool _isLoginPressed = false;
  OverlayEntry? _overlayEntry;

  String formTitleText = 'Email & Password Section';
  double emailAndPasswordFontSize = 30;

  final _formKey = GlobalKey<FormState>();

  // FUNCTIONS:

  void _removeAllOverlays() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // debug register purposes:

  void _prefillDebugData() {
    // Fill controllers with test data
    _emailController.text = "purplecheriandres@gmail.com";
    _passwordController.text = "password123";
    _familyNameController.text = "Smith";
    _nameController.text = "John";
    _cardNumberController.text = "4242 4242 4242 4242"; // Test card (Visa)
    _expController.text = "12/25"; // Expiry date (MM/YY)
    _ccvController.text = "123"; // 3-digit CCV
  }

  void _askUserIfTheyAreChildOrParentOverlay(BuildContext context) {
    var navigator = Navigator.of(context);

    _removeAllOverlays();

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Semi-transparent background
          GestureDetector(
            onTap: () {
              UtilityTopSnackBar.show(
                message: "Please select an option to continue",
                context: context,
                isError: false,
              );
            },
            child: Container(color: Colors.black54),
          ),
          // Main modal content
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    "Are you a Child or a Parent?",
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Parent Button - New Design
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4e88cf), Color(0xFF3a6fb0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          _removeAllOverlays();
                          debugPrint("User selected Parent");
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Text(
                            "I'm a Parent",
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .white, // White text for better contrast
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Child Button - New Design
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFAEDDFF), Color(0xFF8cc5f1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          _removeAllOverlays();
                          UtilityTopSnackBar.show(
                            message: "Your parent needs to register first",
                            context: context,
                            isError: true,
                          );
                          debugPrint("User selected Child");
                          navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Text(
                            "I'm a Child",
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _handleRegisterButtonFunction(BuildContext myContext) async {
    debugPrint("registerAccountPage - handleRegister is called");
    var navigator = Navigator.of(myContext);

    var email = _emailController.text.trim();
    var password = _passwordController.text.trim();
    var family_name = _familyNameController.text.trim();
    var card_name = _nameController.text.trim();
    var card_number = _cardNumberController.text.trim();
    var exp = _expController.value.text.trim();
    var ccv = _ccvController.value.text.trim();
    final format = DateFormat('MM/yy');
    final parsed_exp = format.parse(exp);

    // Step 1: Create an authuser account
    try {
      var create_auth_response =
          await AuthService.registerEmailAndPasswordWithEmailVerification(
            email,
            password,
            context,
          );

      if (create_auth_response["status"] == "success") {
        // Step 2: User is logged in we can now move on to verifying email.
        var user = AuthService.getCurrentUser();
        if (user == null) {
          AuthService.logoutAccount();
          debugPrint("registerPage - abort connection");
          throw Error;
        }

        var user_id = user.uid;

        FamilyModel new_family_model = FamilyModel(
          user_id: user_id,
          family_name: family_name,
          email: email,
          password: password,
        );

        FamilyPaymentInfoModel new_family_payment_info_model =
            FamilyPaymentInfoModel(
              user_id: user_id,
              card_name: card_name,
              card_number: card_number,
              ccv: ccv,
              exp: parsed_exp,
            );

        debugPrint("registerPage - redirecting to verify email page");

        navigator.pushNamed(
          "/verify-email-page",
          arguments: {
            "new-family-model": new_family_model,
            "new-family-payment-info-model": new_family_payment_info_model,
          },
        );
      } else {
        debugPrint("What's my message: ${create_auth_response['message']}");
        debugPrint("What's my status: ${create_auth_response['status']}");

        if (create_auth_response['status'] ==
                "no-family-collection-and-unverified" ||
            create_auth_response['status'] ==
                "no-family-collection-and-no-acount") {
          debugPrint("registerPage - user logged in due to createAuthResponse");
          var user = AuthService.getCurrentUser();
          if (user != null) {
            var user_id = user.uid;
            FamilyModel newFamily = FamilyModel(
              user_id: user_id,
              family_name: family_name,
              email: email,
              password: password,
            );
            FamilyPaymentInfoModel newFamilyPaymentInfo =
                FamilyPaymentInfoModel(
                  user_id: user_id,
                  card_name: card_name,
                  card_number: card_number,
                  ccv: ccv,
                  exp: parsed_exp,
                );

            navigator.pushNamed(
              "/verify-email-page",
              arguments: {
                "new-family-model": newFamily,
                "new-family-payment-info-model": newFamilyPaymentInfo,
              },
            );
          }
        } else {
          debugPrint("loginPage - unwanted statuses:");
          if (create_auth_response['status'] == "account-already-verified") {
            UtilityTopSnackBar.show(
              message: create_auth_response['message'] as String,
              context: context,
              isError: true,
            );
          } else {
            debugPrint("registerPage - unwanted status, return void");
            UtilityTopSnackBar.show(
              message: "ERROR: Connecting to firebase",
              context: context,
              isError: true,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("registerPage - ERROR: Connection lost");
      UtilityTopSnackBar.show(
        message: "ERROR: Connection: $e",
        context: context,
        isError: true,
      );
    }
  }

  // Validators:

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }

    // Updated regex pattern:
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateCcv(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a CCV';
    }
    final ccvRegex = RegExp(r'^\d{3,4}$');
    if (!ccvRegex.hasMatch(value)) {
      return 'CCV must be 3 or 4 digits';
    }
    return null;
  }

  String? _validateExp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter expiration date';
    }
    final expRegex = RegExp(r'^(0[1-9]|1[0-2])/([0-9]{2})$');
    if (!expRegex.hasMatch(value)) {
      return 'Enter expiration date as MM/YY';
    }

    // Validate if the date is in the future
    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Expiration date must be in the future';
    }

    return null;
  }

  // Formatter:

  // Custom Input Formatter for MM/YY
  TextInputFormatter _expInputFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text;
      if (text.length > 5) return oldValue; // Limit to 5 chars (MM/YY)

      String newText = text.replaceAll('/', '');
      if (newText.length > 2) {
        newText =
            '${newText.substring(0, 2)}/${newText.substring(2, newText.length)}';
      }
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    });
  }

  // INITSTATE

  @override
  void initState() {
    super.initState();

    if (is_register_debug_prefiled) {
      _prefillDebugData();
    }

    if (widget.is_broken_register) {
      formTitleText =
          "Broken Registered User detected. Please Register again (make sure email & pass are the same)";
      emailAndPasswordFontSize = 20;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askUserIfTheyAreChildOrParentOverlay(context);
    });
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFCA26),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'KidsBank',
                    style: GoogleFonts.fredoka(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email & Password Section Header
                        Text(
                          formTitleText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: emailAndPasswordFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Email
                        Text(
                          'Email',
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            decoration: InputDecoration(
                              fillColor: const Color(0xFFAEDDFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 3,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              filled: true,
                              hintText: 'example@email.com',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password
                        Text(
                          'Password',
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            decoration: InputDecoration(
                              fillColor: const Color(0xFFAEDDFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 3,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              filled: true,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Family Name
                        Text(
                          'Family Name',
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _familyNameController,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter a family name'
                                : null,
                            decoration: InputDecoration(
                              fillColor: Color(0xFFAEDDFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black, // Set border color here
                                  width: 3,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.red, // Error state border
                                  width: 3,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(
                                16,
                              ), // Add padding for better text alignment
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Divider to separate sections
                        const Divider(
                          color: Colors.black,
                          thickness: 3,
                          height: 30,
                        ),
                        // Credit Card Section Header
                        Text(
                          'Credit Card Section',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name on Card
                        Text(
                          'Name on Card',
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _nameController,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter the name on card'
                                : null,
                            decoration: InputDecoration(
                              fillColor: Color(0xFFAEDDFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black, // Set border color here
                                  width: 3,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.red, // Error state border
                                  width: 3,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(
                                16,
                              ), // Add padding for better text alignment
                              filled: true,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        // Card Number
                        Text(
                          'Card Number',
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // Background color moved here
                          ),
                          child: TextFormField(
                            controller: _cardNumberController,
                            keyboardType: TextInputType.number,
                            maxLength: 14,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter card number'
                                : null,
                            onChanged: (value) {
                              final cleaned = value.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );
                              if (value != cleaned) {
                                _cardNumberController.text = cleaned;
                                _cardNumberController.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(offset: cleaned.length),
                                    );
                              }
                            },
                            decoration: InputDecoration(
                              fillColor: Color(0xFFAEDDFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 3,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              filled:
                                  true, // Keep filled true but color comes from Container
                              // Hide default counter
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Exp and CCV
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Expiry Date',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: TextFormField(
                                      controller: _expController,
                                      validator: _validateExp,
                                      keyboardType: TextInputType.datetime,
                                      maxLength: 5, // MM/YY
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        _expInputFormatter(),
                                      ],
                                      decoration: InputDecoration(
                                        fillColor: const Color(0xFFAEDDFF),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.black,
                                            width: 3,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.black,
                                            width: 3,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.black,
                                            width: 3,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 3,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                        filled: true,
                                        hintText: 'MM/YY',
                                        counterText:
                                            '', // Hide character counter
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CCV',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: TextFormField(
                                      controller: _ccvController,
                                      obscureText:
                                          true, // Always obscure CCV (changed from _obscureCcv)
                                      keyboardType: TextInputType.number,
                                      validator: _validateCcv,
                                      maxLength: 4,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        fillColor: const Color(0xFFAEDDFF),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.black,
                                            width: 3,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.black,
                                            width: 3,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.black,
                                            width: 3,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 3,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                        filled: true,
                                        counterText:
                                            '', // Hide character counter
                                        hintText: '••••', // Shows dots as hint
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _handleRegisterButtonFunction(context);
                                } else {
                                  if (!mounted) return;
                                  UtilityTopSnackBar.show(
                                    message:
                                        'Please fill out all fields correctly!',
                                    context: context,
                                    isError: true,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4e88cf),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(
                                    color: Colors.black, // Black border
                                    width:
                                        3, // 3px width to match other elements
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Register',
                                style: GoogleFonts.fredoka(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.fredoka(),
                      ),
                      GestureDetector(
                        onTapDown: (_) {
                          setState(() {
                            _isLoginPressed = true;
                          });
                        },
                        onTapUp: (_) {
                          setState(() {
                            _isLoginPressed = false;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        onTapCancel: () {
                          setState(() {
                            _isLoginPressed = false;
                          });
                        },
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            fontSize: _isLoginPressed ? 20 : 18,
                            color: _isLoginPressed ? Colors.blue : Colors.black,
                          ),
                          child: const Text('Log In'),
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
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _familyNameController.dispose();
    _nameController.dispose();
    _cardNumberController.dispose();
    _expController.dispose();
    _ccvController.dispose();
    _removeAllOverlays();
    super.dispose();
  }
}

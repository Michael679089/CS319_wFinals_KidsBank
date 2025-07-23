import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/user_model.dart';
import 'login_page.dart';

class RegisterAccountPage extends StatefulWidget {
  const RegisterAccountPage({super.key});

  @override
  State<RegisterAccountPage> createState() => _RegisterAccountPageState();
}

class _RegisterAccountPageState extends State<RegisterAccountPage> {
  // The TextEditingControllers Variables
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _familyNameController;
  late TextEditingController _nameController;
  late TextEditingController _cardNumberController;
  late TextEditingController _expController;
  late TextEditingController _ccvController;

  // My Services
  AuthService myAuthService = AuthService();
  FirestoreAPI myFirestoreAPI = FirestoreAPI();

  // Form Variables
  bool _obscurePassword = true;
  static const bool _obscureCcv = false;
  bool _isLoginPressed = false;
  OverlayEntry? _overlayEntry;

  final _formKey = GlobalKey<FormState>();

  // FUNCTIONS:

  void _removeAllOverlays() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _invokeTopSnackBar(String message, {bool isError = true}) {
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

  void _askUserIfTheyAreChildOrParentOverlay(BuildContext context) {
    var navigator = Navigator.of(context);

    _removeAllOverlays();

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () {
              _invokeTopSnackBar(
                "WARNING: Can't remove overlay, please press a button to continue",
              );
            },
            child: Container(color: Colors.black54),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Question: Are you a Child or a Parent?:",
                    style: GoogleFonts.fredoka(fontSize: 18),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _removeAllOverlays();
                      _invokeTopSnackBar(
                        "Sorry, your parent needs to register first",
                      );
                      debugPrint(
                        "registerAccPage.dart - User selected role child",
                      );
                      navigator.pop(context);
                    },
                    child: const Text("I'm a Child"),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      _removeAllOverlays();
                      debugPrint(
                        "registerAccPage.dart - User selected Parent - Parent confirmed",
                      );
                    },
                    child: const Text("I'm a Parent"),
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

  Future<void> _handleRegister(BuildContext myContext) async {
    var myNavigator = Navigator.of(myContext);

    var email = _emailController.text.trim();
    var password = _passwordController.text.trim();
    var familyName = _familyNameController.text.trim();
    var cardName = _nameController.text.trim();
    var cardNumber = _cardNumberController.text.trim();
    var exp = _expController.value.text.trim();
    var ccv = _ccvController.value.text.trim();

    try {
      UserModel myUserModel = UserModel(
        userId: "",
        familyName: familyName,
        email: email,
        password: password,
        createdAt: "",
      );

      var createAuthAccountResponse = await myAuthService
          .createAccountToFirebaseAuth(
            myUserModel: myUserModel,
            context: myContext,
          );

      if (createAuthAccountResponse["status"] == "success") {
        debugPrint(
          'registerAccPage.dart - Account Created. You are logged in $email but are not allowed to enter until you are verified',
        );
        myNavigator.pushReplacementNamed(
          "/verify-email-page",
          arguments: {
            'register-email': email,
            "family-name": familyName,
            "card-name": cardName,
            "card-number": cardNumber,
            "card-exp": exp,
            "card-ccv": ccv,
          },
        );
      } else if (createAuthAccountResponse["status"] == "email-not-verified") {
        _invokeTopSnackBar('Error: EMail registered but not verified');
        debugPrint("registerAccPage - account isn't verified yet");
        myNavigator.pushReplacementNamed(
          "/verify-email-page",
          arguments: {
            'register-email': email,
            "family-name": familyName,
            "card-name": cardName,
            "card-number": cardNumber,
            "card-exp": exp,
            "card-ccv": ccv,
          },
        );
        debugPrint("registerAccPage - redirecting user to verify-email-page");
      } else {
        _invokeTopSnackBar('Error: Registration failed');
      }

      debugPrint(createAuthAccountResponse.toString());
    } catch (e) {
      _invokeTopSnackBar('Error: ${e.toString()}');
    }
  }

  // Validators
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
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
    final alphanumericRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$');
    if (!alphanumericRegex.hasMatch(value)) {
      return 'Password must contain letters and numbers';
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
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _familyNameController = TextEditingController();
    _nameController = TextEditingController();
    _cardNumberController = TextEditingController();
    _expController = TextEditingController();
    _ccvController = TextEditingController();

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
                          'Email & Password Section',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 30,
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
                            border: Border.all(color: Colors.black, width: 3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFAEDDFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
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
                            border: Border.all(color: Colors.black, width: 3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFAEDDFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
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
                            border: Border.all(color: Colors.black, width: 3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _familyNameController,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter a family name'
                                : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFAEDDFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
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
                            border: Border.all(color: Colors.black, width: 3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _nameController,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter the name on card'
                                : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFAEDDFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
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
                            border: Border.all(color: Colors.black, width: 3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _cardNumberController,
                            keyboardType: TextInputType.number,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter a card number'
                                : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFAEDDFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
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
                                    'Exp',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 3,
                                      ),
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
                                        filled: true,
                                        fillColor: const Color(0xFFAEDDFF),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
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
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: TextFormField(
                                      controller: _ccvController,
                                      obscureText: _obscureCcv,
                                      keyboardType: TextInputType.number,
                                      validator: _validateCcv,
                                      maxLength: 4, // 3 or 4 digits
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: const Color(0xFFAEDDFF),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        counterText:
                                            '', // Hide character counter
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
                              border: Border.all(color: Colors.black, width: 3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _handleRegister(context);
                                } else {
                                  _invokeTopSnackBar(
                                    'Please fill out all fields correctly!',
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

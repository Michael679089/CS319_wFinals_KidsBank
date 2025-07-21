import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/user_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  OverlayEntry? _overlayEntry;
  late BuildContext myContext;

  // Functions:
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  bool isEmail(String? email) {
    if (email == null || email.isEmpty) {
      return false;
    }
    // Regular expression for email validation
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void invokeSnackBar(BuildContext context, String myString) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(myString)));
  }

  void _showOverlay(BuildContext context) {
    // Ensure previous overlay is removed
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Semi-transparent background
          GestureDetector(
            onTap: () {
              invokeSnackBar(
                context,
                "WARNING: Can't remove overlay, please press a button to continue",
              );
            }, // Close overlay on tap
            child: Container(
              color: Colors.black54, // Semi-transparent background
            ),
          ),
          // Centered overlay content
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
                  Text("Question: Are you a Child or a Parent?:"),
                  ElevatedButton(
                    onPressed: () {
                      _removeOverlay();
                      debugPrint(
                        "Child registration: Parent needs to register first",
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("I'm a Child"),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      _removeOverlay();
                      debugPrint("Redirecting to Parent Registration");
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

    // Insert the overlay into the widget tree
    Overlay.of(context).insert(_overlayEntry!);
  }

  // Function to handle registration
  void submitRegisterFunction(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Execute async code
    if (_formKey.currentState!.validate()) {
      // Step 2: Check if Email already exists
      var myFirestore = FirestoreAPI();
      try {
        var doesEmailExist = await myFirestore.doesEmailExist(
          _emailController.text,
        );

        if (doesEmailExist) {
          debugPrint("Email already exists");
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Email already registered'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          debugPrint(
            'Registration submitted: '
            'Family Name: ${_familyNameController.text}, '
            'Email: ${_emailController.text}, '
            'Password: ${_passwordController.text}',
          );

          // add new email and password to fireauth.
          var myAuthService = AuthService();
          String email = _emailController.text;
          String password = _passwordController.text;
          String familyName = _familyNameController.text;
          UserModel myNewUser = UserModel(
            userId: "",
            familyName: familyName,
            email: email,
            password: password,
            createdAt: "",
          );

          if (context.mounted) {
            var createAUTHAccountRes = await myAuthService
                .createAccountToFirebaseAuth(
                  myUserModel: myNewUser,
                  context: context,
                );
            if (createAUTHAccountRes["status"] == "success" ||
                createAUTHAccountRes["status"] == 'email-not-verified') {
              navigator.pushNamed(
                '/verification-email',
                arguments: {
                  'register-email': email,
                  "family-name": familyName,
                  "password": password,
                },
              );
            } else if (createAUTHAccountRes["status"] == "email-verified") {
              debugPrint("ERROR: Account already verified, popping widget");
              navigator.pop();
            } else {
              debugPrint(createAUTHAccountRes.toString());
            }
          } else {
            debugPrint("ERROR: context wasn't mounted while creating account.");
          }
        }
      } catch (e) {
        debugPrint("ERROR: checking email failed. $e");
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error checking email: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      debugPrint("ERROR: Form validation failed");
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // The INIT State:
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use WidgetsBinding to ensure the context is ready
      _showOverlay(myContext);
    });
  }

  // Clean up overlay on widget disposal
  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  // Widget Variables & Form key and controllers
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    myContext = context; // Store context for SnackBar
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Added form key
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                // Family Field
                controller: _familyNameController,
                decoration: const InputDecoration(
                  labelText: 'Family Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a family name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                // Email Field
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!isEmail(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                // Pass Field
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () => submitRegisterFunction(context),
                child: const Text('Register Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

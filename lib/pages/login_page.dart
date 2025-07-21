import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// For Firebase Connection:
import 'package:wfinals_kidsbank/api/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService authService = AuthService();

  // Functions I will reuse:
  checkLoggedInUser() async {
    final AuthService authService = AuthService();
    try {
      var loggedInUserResponse = await authService.checkLoggedInUser();

      if (loggedInUserResponse["isLoggedIn"] == true) {
        debugPrint("LoginPage -> User is Logged In");
        User myUser = loggedInUserResponse["user"] as User;

        //Step 1.1: Check if user's email is verified.
        if (myUser.emailVerified) {
          debugPrint("LoginPage -> User's email is verified");
          debugPrint("-> redirect to Homepage();");
        } else if (!myUser.emailVerified) {
          debugPrint("LoginPage -> User's email IS NOT verified");
          debugPrint("-> redirect to verifyEmailPage();");
        }
      } else if (loggedInUserResponse["isLoggedIn"] == false) {
        debugPrint("LoginPage -> User is NOT Logged In");
      } else {
        debugPrint("ERROR: Cannot detect if user is logged in.");
      }
    } catch (e) {
      debugPrint("ERROR: $e");
    }
  }

  void invokeSnackBar(BuildContext context, String myString) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(myString)));
  }

  // The INIT State
  @override
  void initState() {
    debugPrint("Called initState");
    super.initState();

    // Step 1: Check if there is a User Logged In (reason: Users can quit app and open app).
    checkLoggedInUser();

    debugPrint("Finished initState");
  }

  // Dispose of my controllers if page is replaced or popped.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("HELLO"), // Your provided widget
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: () {
              // Handle login logic
              String email = _emailController.text;
              String password = _passwordController.text;
              if (email.isEmpty || password.isEmpty) {
                invokeSnackBar(context, "Please enter email and password");
              } else {
                invokeSnackBar(context, "Login attempt with $email");
                // Add your AuthService login call here, e.g.:
                // authService.login(email, password).then((response) { ... });
              }
            },
            child: const Text('Login'),
          ),
          const SizedBox(height: 16.0),
          TextButton(
            onPressed: () {
              invokeSnackBar(context, "Navigate to Register Page");
              Navigator.of(context).pushNamed('/register');
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}

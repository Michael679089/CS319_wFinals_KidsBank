import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// For Firebase Connection:
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wfinals_kidsbank/api/auth_service.dart';
import 'package:wfinals_kidsbank/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void invokeSnackBar(BuildContext context, String myString) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(myString)));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    TextField emailTextField = TextField(
      controller: emailController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Enter your email',
      ),
    );

    TextField passwordTextField = TextField(
      controller: passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Enter your password',
      ),
    );

    ElevatedButton loginButton = ElevatedButton(
      onPressed: () async {
        final email = emailController.text.trim();
        final password = passwordController.text.trim();

        if (email.isEmpty || password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email or password cannot be empty.')),
          );
          return;
        } else if (email.isNotEmpty || password.isNotEmpty) {
          var responseLogin = await authService.loginAccountWithEmailAndPass(
            email,
            password,
          );

          var responseLoginStatus = responseLogin["status"];

          if (responseLoginStatus == "success") {
            invokeSnackBar(context, "Hello");
          }
        }
      },
      child: const Text('Login'),
    );

    ElevatedButton registerButton = ElevatedButton(
      onPressed: () {
        debugPrint("Redirecting to Register Page.");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Register_RoleSelector_Page()),
        );
      },
      child: const Text('Register a new account!'),
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Text('Login Page', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 20),
            emailTextField,
            const SizedBox(height: 10),
            passwordTextField,
            const SizedBox(height: 20),
            loginButton,
            const SizedBox(height: 10),
            registerButton,
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/api/auth_service.dart';
import 'package:wfinals_kidsbank/pages/login_page.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  final String pass;

  const VerifyEmailPage(this.email, this.pass, {super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final authService = AuthService();
  bool isButtonDisabled = false;
  int cooldownSeconds = 5;

  Future<void> _checkVerification(String email, String pass) async {
    setState(() => isButtonDisabled = true); // Disable the button immediately

    try {
      var signinTempResponse = await authService.signInTemporary(email, pass);
      if (signinTempResponse == null) return;
      UserCredential userCredential = signinTempResponse;

      User? myUser = userCredential.user;
      if (myUser == null) return;
      await myUser.reload();
      bool isEmailVerified = myUser.emailVerified;

      if (!mounted) return;
      if (!isEmailVerified) {
        try {
          await myUser.sendEmailVerification(); // ✅ Await it
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("📨 Verification email re-sent.")),
          );
        } on FirebaseAuthException catch (e) {
          if (!mounted) return;
          if (e.code == 'too-many-requests') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("🚫 Too many requests. Please wait a while."),
              ),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("❌ Error: ${e.message}")));
          }
          await authService.logoutAccount();
          return;
        }

        await authService.logoutAccount();
        return;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Email verified! Redirecting...")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
        await authService.logoutAccount();
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      // ✅ Always run this, no matter what
      Timer(Duration(seconds: cooldownSeconds), () {
        if (mounted) {
          setState(() => isButtonDisabled = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Your Email")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email_outlined, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                "A verification link has been sent to:",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Text(
                "Please check your inbox and click the link to verify your account.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isButtonDisabled
                    ? null
                    : () => _checkVerification(widget.email, widget.pass),
                child: isButtonDisabled
                    ? const Text("Please wait...")
                    : const Text("I have verified my email!"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

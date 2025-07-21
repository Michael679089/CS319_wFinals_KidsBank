import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/user_model.dart';

class VerificationEmailPage extends StatefulWidget {
  const VerificationEmailPage({super.key});

  @override
  State<VerificationEmailPage> createState() => _VerificationEmailPageState();
}

class _VerificationEmailPageState extends State<VerificationEmailPage> {
  bool _isLoading = false; // Track loading state for async operations

  // Functions:
  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your inbox.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user signed in or email already verified.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send verification email: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          if (!mounted) return;

          // user has been finally verified, add email to user collection
          var myFirestoreAPI = FirestoreAPI();
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, String>;
          UserModel newUser = UserModel(
            userId: user.uid,
            familyName: args["family-name"] as String,
            email: user.email as String,
            password: args["password"] as String,
            createdAt: FieldValue.serverTimestamp().toString(),
          );
          myFirestoreAPI.addAuthUserToUserCollection(newUser);

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false, // Clear navigation stack
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not yet verified. Please check your inbox.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking verification status: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>;
    var email = args['register-email'];

    if (email == null) {
      Navigator.pop(context);
      return Scaffold();
    }

    // made sure email is not null

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Please verify your email address to continue.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              Text(
                email,
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              const Text(
                'A verification email has been sent to your inbox. '
                'Click the link in the email to verify your account.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _sendVerificationEmail,
                          child: const Text('Resend Verification Email'),
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _checkVerificationStatus,
                          child: const Text('I’ve Verified My Email'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

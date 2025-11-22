import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:newmanbarber/telas/home_page.dart';
import 'package:newmanbarber/telas/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // If the snapshot has data, it means the user is logged in
        if (snapshot.hasData) {
          return const HomePage();
        }
        
        // Otherwise, the user is not logged in
        return const LoginPage();
      },
    );
  }
}

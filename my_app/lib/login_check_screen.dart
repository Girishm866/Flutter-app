import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_home_screen.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';

class LoginCheckScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());

        if (!snapshot.hasData) return LoginScreen();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
          builder: (context, snap) {
            if (!snap.hasData) return Center(child: CircularProgressIndicator());

            final role = snap.data!['role'] ?? 'user';

            if (role == 'admin') {
              return AdminDashboardScreen();
            } else {
              return UserHomeScreen();
            }
          },
        );
      },
    );
  }
}

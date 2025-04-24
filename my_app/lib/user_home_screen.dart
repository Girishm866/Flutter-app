import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHomeScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome, ${user?.email ?? "User"}!'),
      ),
    );
  }
}

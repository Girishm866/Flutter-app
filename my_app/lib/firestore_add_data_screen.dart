import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'match_create_screen.dart';
import 'match_list_screen.dart';
import 'user_profile_screen.dart';

class FirestoreAddDataScreen extends StatefulWidget {
  @override
  _FirestoreAddDataScreenState createState() => _FirestoreAddDataScreenState();
}

class _FirestoreAddDataScreenState extends State<FirestoreAddDataScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  void addUserData() {
    FirebaseFirestore.instance.collection('users').add({
      'name': nameController.text,
      'email': emailController.text,
      'createdAt': Timestamp.now(),
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data Added Successfully!')),
      );
      nameController.clear();
      emailController.clear();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to Add Data: $error')),
      );
    });
  }

  void navigateToMatchCreate() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => MatchCreateScreen()));
  }

  void navigateToMatchList() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => MatchListScreen()));
  }

  void navigateToProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: navigateToProfile,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Enter Name'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Enter Email'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: addUserData, child: Text('Add User Data')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: navigateToMatchCreate, child: Text('Create Match')),
            SizedBox(height: 10),
            ElevatedButton(onPressed: navigateToMatchList, child: Text('View Matches')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  Future<int> getJoinedMatchesCount(String uid) async {
    final matchesSnapshot = await FirebaseFirestore.instance.collection('matches').get();
    int count = 0;
    for (var match in matchesSnapshot.docs) {
      final joinedUsers = match.data()['joinedUsers'] ?? [];
      if (joinedUsers.contains(uid)) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;
    final email = user?.email ?? 'No Email';

    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: FutureBuilder<int>(
        future: getJoinedMatchesCount(uid!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: $email', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Matches Joined: ${snapshot.data}', style: TextStyle(fontSize: 18)),
                Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pop(context);
                    },
                    child: Text('Logout'),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

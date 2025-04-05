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

  Future<int> getWalletBalance(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data()?['wallet'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;
    final email = user?.email ?? 'No Email';

    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: FutureBuilder(
        future: Future.wait([
          getJoinedMatchesCount(uid!),
          getWalletBalance(uid),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final matchesCount = snapshot.data?[0] ?? 0;
          final walletBalance = snapshot.data?[1] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: $email', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Matches Joined: $matchesCount', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Wallet Balance: ₹$walletBalance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
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

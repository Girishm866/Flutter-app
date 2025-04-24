import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinedMatchScreen extends StatelessWidget {
  final String matchId;
  JoinedMatchScreen({required this.matchId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Match Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('matches').doc(matchId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final match = snapshot.data!;
          final isJoined = (match['players'] as List).contains(uid);

          if (!isJoined) return Center(child: Text("You haven't joined this match"));

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Room ID: ${match['roomId'] ?? "TBA"}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Room Password: ${match['roomPassword'] ?? "TBA"}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Match Rules:\n${match['rules'] ?? "No special rules"}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Back"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

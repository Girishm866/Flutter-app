import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'match_details_screen.dart';
import 'user_profile_screen.dart';

class MatchListScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  void joinMatch(String matchId, BuildContext context) async {
    final uid = user?.uid;
    if (uid == null) return;

    final matchRef = FirebaseFirestore.instance.collection('matches').doc(matchId);
    final matchSnapshot = await matchRef.get();
    final data = matchSnapshot.data() as Map<String, dynamic>;
    final List<dynamic> joinedUsers = data['joinedUsers'] ?? [];

    if (joinedUsers.contains(uid)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Already Joined')));
      return;
    }

    await matchRef.update({
      'joinedUsers': FieldValue.arrayUnion([uid]),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joined Match Successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Matches'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfileScreen()),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data?.docs ?? [];

          if (matches.isEmpty) {
            return Center(child: Text('No Matches Found'));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final matchId = match.id;
              final title = match['title'];
              final entryFee = match['entryFee'];
              final prizePool = match['prizePool'];

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text('Entry: ₹$entryFee | Prize: ₹$prizePool'),
                  trailing: ElevatedButton(
                    child: Text('Join'),
                    onPressed: () => joinMatch(matchId, context),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchDetailsScreen(matchId: matchId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

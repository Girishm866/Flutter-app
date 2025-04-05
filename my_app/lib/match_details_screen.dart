import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchDetailsScreen extends StatelessWidget {
  final String matchId;

  MatchDetailsScreen({required this.matchId});

  @override
  Widget build(BuildContext context) {
    final matchRef = FirebaseFirestore.instance.collection('matches').doc(matchId);

    return Scaffold(
      appBar: AppBar(title: Text('Match Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: matchRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Match not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final title = data['title'];
          final entryFee = data['entryFee'];
          final prizePool = data['prizePool'];
          final List<dynamic> joinedUsers = data['joinedUsers'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title: $title', style: TextStyle(fontSize: 20)),
                Text('Entry Fee: ₹$entryFee'),
                Text('Prize Pool: ₹$prizePool'),
                SizedBox(height: 20),
                Text('Joined Users:', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: joinedUsers.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text('User ID: ${joinedUsers[index]}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

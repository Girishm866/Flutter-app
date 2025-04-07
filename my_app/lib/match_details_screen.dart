import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchDetailsScreen extends StatelessWidget {
  final DocumentSnapshot match;

  MatchDetailsScreen({required this.match});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${match['matchName']} Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entry Fee: ₹${match['entryFee']}'),
            Text('Prize Pool: ${match['prizePool']}'),
            Text('Game Mode: ${match['gameMode']}'),
            SizedBox(height: 20),
            Text('Joined Players:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('matches')
                    .doc(match.id)
                    .collection('participants')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final participants = snapshot.data!.docs;

                  if (participants.isEmpty) {
                    return Text('No players joined yet.');
                  }

                  return ListView.builder(
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text('Player ${index + 1}'),
                        subtitle: Text('Joined at: ${participants[index]['joinedAt'].toDate()}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

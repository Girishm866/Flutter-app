import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinMatchScreen extends StatefulWidget {
  @override
  _JoinMatchScreenState createState() => _JoinMatchScreenState();
}

class _JoinMatchScreenState extends State<JoinMatchScreen> {
  String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> joinMatch(DocumentSnapshot match) async {
    final entryFee = match['entryFee'];
    final walletRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final walletSnap = await walletRef.get();
    final currentBalance = walletSnap.data()?['wallet'] ?? 0;

    // Double join check
    final participantDoc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(match.id)
        .collection('participants')
        .doc(userId)
        .get();

    if (participantDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have already joined this match.')),
      );
      return;
    }

    if (currentBalance >= entryFee) {
      await walletRef.update({'wallet': currentBalance - entryFee});
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(match.id)
          .collection('participants')
          .doc(userId)
          .set({'joinedAt': Timestamp.now()});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Match joined successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough balance in wallet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Match')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final matches = snapshot.data!.docs;

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(match['matchName']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Entry Fee: ₹${match['entryFee']}'),
                      Text('Prize Pool: ${match['prizePool']}'),
                      Text('Game Mode: ${match['gameMode']}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    child: Text('Join'),
                    onPressed: () => joinMatch(match),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  void openMatchDetails(DocumentSnapshot match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailsScreen(match: match),
      ),
    );
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

              final gameType = match['gameType']; // BR, CS, Lone Wolf
              final mode = match['mode']; // 1v1, 2v2, etc.

              // Auto values logic
              int entryFee = 0;
              int perKillReward = 0;
              int prizePool = 0;

              if (gameType == 'BR') {
                if (mode == 'Solo') {
                  entryFee = 10;
                  perKillReward = 5;
                  prizePool = 100;
                } else if (mode == 'Squad') {
                  entryFee = 20;
                  perKillReward = 10;
                  prizePool = 200;
                }
              } else if (gameType == 'CS') {
                if (mode == '1v1') {
                  entryFee = 15;
                  perKillReward = 7;
                  prizePool = 120;
                } else if (mode == '2v2') {
                  entryFee = 25;
                  perKillReward = 12;
                  prizePool = 250;
                }
              } else if (gameType == 'Lone Wolf') {
                entryFee = 5;
                perKillReward = 2;
                prizePool = 50;
              }

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(match['matchName']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Game: $gameType | Mode: $mode'),
                      Text('Entry Fee: ₹$entryFee'),
                      Text('Per Kill: ₹$perKillReward'),
                      Text('Prize Pool: ₹$prizePool'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    child: Text('Join'),
                    onPressed: () => joinMatch(match),
                  ),
                  onTap: () => openMatchDetails(match),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

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
            Text('Prize Pool: ₹${match['prizePool']}'),
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
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());
                  final participants = snapshot.data!.docs;

                  if (participants.isEmpty) {
                    return Text('No players joined yet.');
                  }

                  return ListView.builder(
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final joinedTime = DateFormat('dd MMM yyyy, hh:mm a')
                          .format(participants[index]['joinedAt'].toDate());
                      return ListTile(
                        title: Text('Player ${index + 1}'),
                        subtitle: Text('Joined at: $joinedTime'),
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

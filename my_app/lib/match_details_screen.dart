import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchDetailsScreen extends StatefulWidget {
  final DocumentSnapshot match;

  MatchDetailsScreen({required this.match});

  @override
  _MatchDetailsScreenState createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  final winnerUidController = TextEditingController();
  final winnerNameController = TextEditingController();
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    checkAdmin();
  }

  Future<void> checkAdmin() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && doc.data()?['role'] == 'admin') {
      setState(() {
        isAdmin = true;
      });
    }
  }

  Future<void> uploadMatchResult(String winnerUid, String winnerName, int prizeAmount) async {
    final matchRef = FirebaseFirestore.instance.collection('matches').doc(widget.match.id);
    final userRef = FirebaseFirestore.instance.collection('users').doc(winnerUid);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final matchSnap = await txn.get(matchRef);
      final userSnap = await txn.get(userRef);

      if (!matchSnap.exists || !userSnap.exists) {
        throw Exception("Match or User not found");
      }

      int currentBalance = userSnap['wallet'] ?? 0;

      txn.update(matchRef, {
        'isCompleted': true,
        'winnerUid': winnerUid,
        'winnerName': winnerName,
      });

      txn.update(userRef, {
        'wallet': currentBalance + prizeAmount,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Winner Selected & Prize Given')));
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

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
            if (isAdmin) ...[
              Divider(),
              TextField(
                controller: winnerUidController,
                decoration: InputDecoration(labelText: 'Winner UID'),
              ),
              TextField(
                controller: winnerNameController,
                decoration: InputDecoration(labelText: 'Winner Name'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  final uid = winnerUidController.text.trim();
                  final name = winnerNameController.text.trim();
                  final prize = match['prizePool'];
                  if (uid.isNotEmpty && name.isNotEmpty) {
                    uploadMatchResult(uid, name, prize);
                  }
                },
                child: Text("Upload Result & Give Prize"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

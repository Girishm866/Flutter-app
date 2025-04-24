import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KillSubmitScreen extends StatefulWidget {
  @override
  _KillSubmitScreenState createState() => _KillSubmitScreenState();
}

class _KillSubmitScreenState extends State<KillSubmitScreen> {
  final _matchIdController = TextEditingController();
  final _killsController = TextEditingController();

  Future<void> _submitKills() async {
    final user = FirebaseAuth.instance.currentUser;
    final matchId = _matchIdController.text.trim();
    final kills = int.tryParse(_killsController.text.trim());

    if (matchId.isEmpty || kills == null) return;

    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('submissions')
        .doc(user!.uid)
        .set({
      'userId': user.uid,
      'kills': kills,
      'submittedAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kills submitted')));
    _matchIdController.clear();
    _killsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Submit Kills')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _matchIdController,
              decoration: InputDecoration(labelText: 'Match ID'),
            ),
            TextField(
              controller: _killsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Total Kills'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitKills,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

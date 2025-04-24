import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultUploadScreen extends StatefulWidget {
  @override
  _ResultUploadScreenState createState() => _ResultUploadScreenState();
}

class _ResultUploadScreenState extends State<ResultUploadScreen> {
  final _matchIdController = TextEditingController();
  final _winnerUidController = TextEditingController();

  Future<void> _uploadResult() async {
    final matchId = _matchIdController.text.trim();
    final winnerUid = _winnerUidController.text.trim();

    if (matchId.isEmpty || winnerUid.isEmpty) return;

    await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
      'winnerUid': winnerUid,
      'resultUploaded': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Result uploaded')));
    _matchIdController.clear();
    _winnerUidController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Match Result')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _matchIdController,
              decoration: InputDecoration(labelText: 'Match ID'),
            ),
            TextField(
              controller: _winnerUidController,
              decoration: InputDecoration(labelText: 'Winner UID'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _uploadResult,
              child: Text('Upload Result'),
            ),
          ],
        ),
      ),
    );
  }
}

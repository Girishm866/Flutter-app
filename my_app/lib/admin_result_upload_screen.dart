import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminResultUploadScreen extends StatefulWidget {
  @override
  _AdminResultUploadScreenState createState() => _AdminResultUploadScreenState();
}

class _AdminResultUploadScreenState extends State<AdminResultUploadScreen> {
  final _matchIdController = TextEditingController();
  final _winnerNameController = TextEditingController();
  final _killsController = TextEditingController();
  final _placementPointsController = TextEditingController();

  Future<void> _uploadResult() async {
    if (_matchIdController.text.isEmpty || _winnerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill required fields')));
      return;
    }

    final matchDoc = FirebaseFirestore.instance.collection('matches').doc(_matchIdController.text);

    await matchDoc.update({
      'winner': _winnerNameController.text,
      'kills': int.tryParse(_killsController.text) ?? 0,
      'placementPoints': int.tryParse(_placementPointsController.text) ?? 0,
      'resultUploaded': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Result uploaded successfully')));
    _matchIdController.clear();
    _winnerNameController.clear();
    _killsController.clear();
    _placementPointsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Match Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _matchIdController,
              decoration: InputDecoration(labelText: 'Match ID'),
            ),
            TextField(
              controller: _winnerNameController,
              decoration: InputDecoration(labelText: 'Winner Name'),
            ),
            TextField(
              controller: _killsController,
              decoration: InputDecoration(labelText: 'Total Kills'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _placementPointsController,
              decoration: InputDecoration(labelText: 'Placement Points'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
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

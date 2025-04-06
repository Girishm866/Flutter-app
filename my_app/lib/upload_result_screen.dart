import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadResultScreen extends StatefulWidget {
  @override
  State<UploadResultScreen> createState() => _UploadResultScreenState();
}

class _UploadResultScreenState extends State<UploadResultScreen> {
  String selectedMatchId = '';
  final resultController = TextEditingController();

  Future<void> updateResult() async {
    if (selectedMatchId.isEmpty || resultController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select match and enter result')));
      return;
    }

    await FirebaseFirestore.instance.collection('matches').doc(selectedMatchId).update({
      'result': resultController.text.trim()
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Result updated')));
    resultController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Match Result')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('matches').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final matches = snapshot.data!.docs;
                return DropdownButton<String>(
                  hint: Text('Select Match'),
                  value: selectedMatchId.isEmpty ? null : selectedMatchId,
                  items: matches.map((match) {
                    return DropdownMenuItem<String>(
                      value: match.id,
                      child: Text(match['title']),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedMatchId = val!),
                );
              },
            ),
            TextField(
              controller: resultController,
              decoration: InputDecoration(labelText: 'Enter Result (e.g., UID123 won)'),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: updateResult, child: Text('Upload Result'))
          ],
        ),
      ),
    );
  }
}

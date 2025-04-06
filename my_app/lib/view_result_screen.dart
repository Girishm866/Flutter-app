import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchResultScreen extends StatefulWidget {
  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> {
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
    setState(() {}); // Refresh view
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload & View Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Upload result section
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
            SizedBox(height: 10),
            ElevatedButton(onPressed: updateResult, child: Text('Upload Result')),

            Divider(height: 30),

            // View results section
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('matches').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                final matches = snapshot.data!.docs;

                if (matches.isEmpty) {
                  return Text('No match results found.');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    final title = match['title'];
                    final result = match.data().containsKey('result') ? match['result'] : 'Result not uploaded';

                    return ListTile(
                      title: Text(title),
                      subtitle: Text('Result: $result'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

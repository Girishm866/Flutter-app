import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Match Results')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('matches').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final matches = snapshot.data!.docs;

          if (matches.isEmpty) {
            return Center(child: Text('No match results found.'));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final title = match['title'];
              final result = match.data().toString().contains('result') ? match['result'] : 'Result not uploaded';

              return ListTile(
                title: Text(title),
                subtitle: Text('Result: $result'),
              );
            },
          );
        },
      ),
    );
  }
}

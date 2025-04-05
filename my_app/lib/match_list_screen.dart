import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Available Matches')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('matches').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data?.docs ?? [];

          if (matches.isEmpty) {
            return Center(child: Text('No Matches Found'));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final title = match['title'];
              final entryFee = match['entryFee'];
              final prizePool = match['prizePool'];

              return ListTile(
                title: Text(title),
                subtitle: Text('Entry Fee: ₹$entryFee | Prize: ₹$prizePool'),
              );
            },
          );
        },
      ),
    );
  }
}

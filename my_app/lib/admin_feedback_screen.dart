import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeedbackScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Feedbacks')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final feedbacks = snapshot.data!.docs;

          if (feedbacks.isEmpty) {
            return Center(child: Text('No feedback found.'));
          }

          return ListView.builder(
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              final feedback = feedbacks[index];
              final message = feedback['message'] ?? '';
              final userId = feedback['userId'] ?? 'Unknown';

              return ListTile(
                leading: Icon(Icons.feedback),
                title: Text('User: $userId'),
                subtitle: Text(message),
              );
            },
          );
        },
      ),
    );
  }
}

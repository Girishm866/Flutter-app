import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationScreen extends StatefulWidget {
  @override
  _AdminNotificationScreenState createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final notificationController = TextEditingController();

  Future<void> sendNotification() async {
    final message = notificationController.text.trim();
    if (message.isEmpty) return;

    await FirebaseFirestore.instance.collection('notifications').add({
      'message': message,
      'timestamp': Timestamp.now(),
    });

    notificationController.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notification sent')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Send Notification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: notificationController,
              decoration: InputDecoration(labelText: 'Enter notification message'),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: sendNotification,
              child: Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

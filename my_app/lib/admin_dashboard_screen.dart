import 'package:flutter/material.dart';
import 'admin_match_management.dart';
import 'admin_notification_screen.dart';
import 'admin_leaderboard_screen.dart';
import 'admin_feedback_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminMatchManagement())),
              child: Text('Manage Matches'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminNotificationScreen())),
              child: Text('Send Notification'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminLeaderboardScreen())),
              child: Text('Leaderboard Control'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminFeedbackScreen())),
              child: Text('View Feedbacks'),
            ),
          ],
        ),
      ),
    );
  }
}

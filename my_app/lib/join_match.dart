import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JoinMatchScreen extends StatelessWidget {
  final String matchId;

  const JoinMatchScreen({super.key, required this.matchId});

  Future<void> joinMatch(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return;

    final matchDoc = FirebaseFirestore.instance.collection('matches').doc(matchId);
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    final matchSnapshot = await matchDoc.get();
    final userSnapshot = await userDoc.get();

    final entryFee = matchSnapshot.data()?['entryFee'] ?? 0;
    final currentBalance = userSnapshot.data()?['wallet'] ?? 0;
    final List joinedUsers = matchSnapshot.data()?['joinedUsers'] ?? [];

    if (joinedUsers.contains(uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Already joined this match')),
      );
      return;
    }

    if (currentBalance < entryFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough balance')),
      );
      return;
    }

    // Wallet update & UID add
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.update(userDoc, {
        'wallet': currentBalance - entryFee,
      });

      transaction.update(matchDoc, {
        'joinedUsers': FieldValue.arrayUnion([uid]),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Match joined successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Match')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => joinMatch(context),
          child: Text('Join Match'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class SpinScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  void spinAndAddMoney(BuildContext context) async {
    final uid = user!.uid;
    final doc = FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await doc.get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final spinDoc = FirebaseFirestore.instance.collection('spin').doc(uid);
    final spinSnap = await spinDoc.get();
    final lastSpin = spinSnap.exists ? spinSnap['lastSpin'].toDate() : DateTime(2000);

    final lastSpinDate = DateTime(lastSpin.year, lastSpin.month, lastSpin.day);

    if (lastSpinDate == today) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("आज आपने पहले ही Spin कर लिया है")));
      return;
    }

    final reward = [0, 5, 10, 20, 0, 15][Random().nextInt(6)];
    final wallet = snap['wallet'] ?? 0;
    await doc.update({'wallet': wallet + reward});
    await spinDoc.set({'lastSpin': now});

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('आपने ₹$reward जीते!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Spin & Win')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => spinAndAddMoney(context),
          child: Text('Spin Now'),
        ),
      ),
    );
  }
}

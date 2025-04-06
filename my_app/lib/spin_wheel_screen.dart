import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpinToWinScreen extends StatefulWidget {
  @override
  _SpinToWinScreenState createState() => _SpinToWinScreenState();
}

class _SpinToWinScreenState extends State<SpinToWinScreen> {
  double angle = 0;
  bool isSpinning = false;
  final List<int> rewards = [5, 10, 20, 0, 50, 100, 0, 15];

  void spinWheel() async {
    if (isSpinning) return;

    setState(() => isSpinning = true);

    final random = Random();
    final rewardIndex = random.nextInt(rewards.length);
    final reward = rewards[rewardIndex];

    setState(() {
      angle += 2 * pi * 5 + (pi * 2 / rewards.length) * rewardIndex;
    });

    await Future.delayed(Duration(seconds: 4));
    await updateWallet(reward);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You won ₹$reward!')),
    );

    setState(() => isSpinning = false);
  }

  Future<void> updateWallet(int reward) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    final currentWallet = snapshot['wallet'] ?? 0;

    await docRef.update({'wallet': currentWallet + reward});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Spin to Win')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: angle,
            child: Image.asset('assets/spin_wheel.png', height: 250), // Add your wheel image
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: spinWheel,
            child: Text(isSpinning ? 'Spinning...' : 'SPIN'),
          ),
        ],
      ),
    );
  }
}

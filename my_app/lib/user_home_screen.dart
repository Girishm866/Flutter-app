import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserHomeScreen extends StatefulWidget {
  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  int wallet = 0;
  String name = '';
  String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      name = doc['name'] ?? '';
      wallet = doc['wallet'] ?? 0;
    });
  }

  Future<void> spinReward() async {
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await userRef.get();
    if (snap['lastSpin'] != now) {
      final reward = [5, 10, 15, 20].elementAt(Random().nextInt(4));
      await userRef.update({
        'wallet': FieldValue.increment(reward),
        'lastSpin': now,
      });
      setState(() => wallet += reward);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You won ₹$reward')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Already spun today!')));
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> joinMatch(DocumentSnapshot match) async {
    final entryFee = match['entryFee'];
    if (wallet >= entryFee) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'wallet': FieldValue.increment(-entryFee),
      });
      await FirebaseFirestore.instance.collection('matches').doc(match.id).update({
        'players': FieldValue.arrayUnion([uid]),
      });
      fetchUserData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joined match!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not enough balance')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $name'),
        actions: [
          IconButton(onPressed: logout, icon: Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Wallet: ₹$wallet'),
            trailing: ElevatedButton(onPressed: spinReward, child: Text('Daily Spin')),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('matches').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final matches = snapshot.data!.docs;
                if (matches.isEmpty) return Center(child: Text('No matches available'));
                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return Card(
                      child: ListTile(
                        title: Text('${match['type']} | ${match['mode']}'),
                        subtitle: Text('Entry: ₹${match['entryFee']} | Kill: ₹${match['perKill']}'),
                        trailing: ElevatedButton(
                          onPressed: () => joinMatch(match),
                          child: Text('Join'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

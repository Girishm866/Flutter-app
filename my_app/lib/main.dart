import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: AuthScreen()));
}

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;

  Future<void> handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final auth = FirebaseAuth.instance;

    try {
      if (isLogin) {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'email': email,
          'wallet': 100,
          'role': 'user'
        });
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
          TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          SizedBox(height: 20),
          ElevatedButton(onPressed: handleAuth, child: Text(isLogin ? 'Login' : 'Register')),
          TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? 'Create Account' : 'Already have an account?'))
        ]),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tournament App')),
      body: Column(children: [
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final wallet = data?['wallet'] ?? 0;
            return ListTile(
                title: Text('Welcome ${user!.email}'),
                subtitle: Text('Wallet: ₹$wallet'));
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('matches').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              final matches = snapshot.data!.docs;
              return ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return ListTile(
                    title: Text(match['title']),
                    subtitle: Text('Entry Fee: ₹${match['entryFee']}'),
                    trailing: Text('Slots: ${match['slots']}'),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: () => MatchDetailsScreen(matchId: match.id))),
                  );
                },
              );
            },
          ),
        )
      ]),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text(user!.email ?? '')),
            ListTile(title: Text('Create Match'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: () => CreateMatchScreen()))),
            ListTile(title: Text('Profile'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: () => ProfileScreen()))),
            ListTile(title: Text('Leaderboard'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: () => LeaderboardScreen()))),
            ListTile(title: Text('Add Money'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddMoneyScreen()))),
            ListTile(title: Text('Spin to Win'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpinScreen()))),
            ListTile(title: Text('Chat'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen()))),
            ListTile(title: Text('Notifications'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen()))),
            ListTile(title: Text('Logout'), onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthScreen()));
            }),
          ],
        ),
      ),
    );
  }
}
class AddMoneyScreen extends StatefulWidget {
  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final amountController = TextEditingController();

  Future<void> addMoney() async {
    final amount = int.tryParse(amountController.text.trim()) ?? 0;
    if (amount < 5 || amount > 500) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("₹5 से ₹500 तक ही ऐड कर सकते हो")));
      return;
    }

    final doc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final current = snap['wallet'] ?? 0;
      tx.update(doc, {'wallet': current + amount});
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('₹$amount ऐड हो गया')));
    amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Money')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: amountController, decoration: InputDecoration(labelText: '₹5 - ₹500'), keyboardType: TextInputType.number),
          SizedBox(height: 20),
          ElevatedButton(onPressed: addMoney, child: Text('Add to Wallet'))
        ]),
      ),
    );
  }
}

class MatchDetailsScreen extends StatelessWidget {
  final String matchId;

  MatchDetailsScreen({required this.matchId});

  final user = FirebaseAuth.instance.currentUser;

  Future<void> joinMatch(BuildContext context, int entryFee) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    final snap = await doc.get();
    final wallet = snap['wallet'] ?? 0;

    if (wallet < entryFee) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('पैसे कम हैं')));
      return;
    }

    await doc.update({'wallet': wallet - entryFee});
    await FirebaseFirestore.instance.collection('matches').doc(matchId).collection('players').doc(user!.uid).set({
      'email': user!.email,
      'joinedAt': DateTime.now()
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('मैच जॉइन कर लिया')));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('matches').doc(matchId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Scaffold(body: Center(child: CircularProgressIndicator()));
        final match = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text('Match Details')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(match['title'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Entry Fee: ₹${match['entryFee']}'),
                Text('Total Slots: ${match['slots']}'),
                SizedBox(height: 20),
                ElevatedButton(onPressed: () => joinMatch(context, match['entryFee']), child: Text('Join Match'))
              ],
            ),
          ),
        );
      },
    );
  }
}

class CreateMatchScreen extends StatelessWidget {
  final titleController = TextEditingController();
  final feeController = TextEditingController();
  final slotController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Match')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: titleController, decoration: InputDecoration(labelText: 'Match Title')),
          TextField(controller: feeController, decoration: InputDecoration(labelText: 'Entry Fee'), keyboardType: TextInputType.number),
          TextField(controller: slotController, decoration: InputDecoration(labelText: 'Total Slots'), keyboardType: TextInputType.number),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
              if (doc['role'] != 'admin') {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Access Denied')));
                return;
              }

              await FirebaseFirestore.instance.collection('matches').add({
                'title': titleController.text.trim(),
                'entryFee': int.parse(feeController.text.trim()),
                'slots': int.parse(slotController.text.trim()),
              });
              Navigator.pop(context);
            },
            child: Text('Create Match'))
        ]),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          return ListTile(
            title: Text('Email: ${user!.email}'),
            subtitle: Text('Wallet: ₹${data['wallet'] ?? 0}\nRole: ${data['role'] ?? "user"}'),
          );
        },
      ),
    );
  }
}

class LeaderboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leaderboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('wallet', descending: true).limit(10).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user['email']),
                trailing: Text('₹${user['wallet']}'),
              );
            },
          );
        },
      ),
    );
  }
}

class SpinScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  void spinAndAddMoney(BuildContext context) async {
    final reward = [0, 5, 10, 20, 0, 15][Random().nextInt(6)];
    final doc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    final snap = await doc.get();
    final wallet = snap['wallet'] ?? 0;
    await doc.update({'wallet': wallet + reward});

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You won ₹$reward!')));
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

class ChatScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;
  final msgController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Global Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chat').orderBy('time').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView(
                  children: messages.map((msg) => ListTile(title: Text(msg['text']), subtitle: Text(msg['email']))).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: msgController, decoration: InputDecoration(hintText: 'Message...'))),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    if (msgController.text.trim().isEmpty) return;
                    await FirebaseFirestore.instance.collection('chat').add({
                      'email': user!.email,
                      'text': msgController.text.trim(),
                      'time': DateTime.now()
                    });
                    msgController.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  final notifications = [
    'New tournament added!',
    'Wallet offer: Add ₹100 and get ₹20 bonus!',
    'Top 3 players win special rewards!',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) => ListTile(
          leading: Icon(Icons.notifications),
          title: Text(notifications[index]),
        ),
      ),
    );
  }
}

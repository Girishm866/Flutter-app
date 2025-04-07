import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

final auth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: auth.currentUser == null ? AuthScreen() : HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  void handleAuth(BuildContext context, bool isLogin) async {
    try {
      if (isLogin) {
        await auth.signInWithEmailAndPassword(
            email: emailController.text, password: passController.text);
      } else {
        final userCred = await auth.createUserWithEmailAndPassword(
            email: emailController.text, password: passController.text);
        await firestore.collection('users').doc(userCred.user!.uid).set({
          'email': emailController.text,
          'wallet': 0,
          'role': 'user',
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
      appBar: AppBar(title: Text('Tournament App')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
          TextField(controller: passController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          SizedBox(height: 20),
          ElevatedButton(onPressed: () => handleAuth(context, true), child: Text('Login')),
          ElevatedButton(onPressed: () => handleAuth(context, false), child: Text('Register')),
        ]),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final user = auth.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome ${user.email}')),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text('Menu')),
            ListTile(title: Text('Profile'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()))),
            ListTile(title: Text('Matches'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchListScreen()))),
            ListTile(title: Text('Leaderboard'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen()))),
            ListTile(title: Text('Spin to Win'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpinScreen()))),
            ListTile(title: Text('Notifications'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen()))),
            ListTile(title: Text('Chat'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen()))),
            ListTile(title: Text('Logout'), onTap: () => auth.signOut().then((_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthScreen())))),
          ],
        ),
      ),
      body: Center(
        child: FutureBuilder<DocumentSnapshot>(
          future: firestore.collection('users').doc(user.uid).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return CircularProgressIndicator();
            final data = snapshot.data!.data() as Map<String, dynamic>;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Email: ${data['email']}'),
                Text('Wallet: ₹${data['wallet']}'),
                ElevatedButton(onPressed: () => addMoney(user.uid), child: Text('Add Money')),
                if (data['role'] == 'admin')
                  ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchCreateScreen())), child: Text('Create Match')),
              ],
            );
          },
        ),
      ),
    );
  }

  void addMoney(String uid) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        int amount = 10;
        return AlertDialog(
          title: Text('Add Money'),
          content: DropdownButton<int>(
            value: amount,
            onChanged: (val) => amount = val!,
            items: [5, 10, 20, 50, 100, 200, 500].map((e) => DropdownMenuItem(value: e, child: Text('₹$e'))).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final doc = firestore.collection('users').doc(uid);
                final snap = await doc.get();
                final current = (snap.data() as Map<String, dynamic>)['wallet'];
                await doc.update({'wallet': current + amount});
                Navigator.pop(context);
              },
              child: Text('Add'),
            )
          ],
        );
      },
    );
  }
}

final navigatorKey = GlobalKey<NavigatorState>();

class MatchCreateScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final entryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Match')),
      body: Column(
        children: [
          TextField(controller: nameController, decoration: InputDecoration(labelText: 'Match Name')),
          TextField(controller: entryController, decoration: InputDecoration(labelText: 'Entry Fee'), keyboardType: TextInputType.number),
          ElevatedButton(
            onPressed: () {
              firestore.collection('matches').add({
                'name': nameController.text,
                'entry': int.parse(entryController.text),
              });
              Navigator.pop(context);
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }
}

class MatchListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Matches')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('matches').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          final matches = snapshot.data!.docs;
          return ListView(
            children: matches.map((match) {
              final data = match.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name']),
                subtitle: Text('Entry: ₹${data['entry']}'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(match.id, data))),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class MatchDetailScreen extends StatelessWidget {
  final String matchId;
  final Map<String, dynamic> data;

  MatchDetailScreen(this.matchId, this.data);

  void joinMatch(BuildContext context) async {
    final doc = firestore.collection('users').doc(auth.currentUser!.uid);
    final snap = await doc.get();
    final wallet = (snap.data() as Map<String, dynamic>)['wallet'];
    if (wallet >= data['entry']) {
      await doc.update({'wallet': wallet - data['entry']});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Match Joined!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insufficient Balance')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(data['name'])),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Entry Fee: ₹${data['entry']}'),
          ElevatedButton(onPressed: () => joinMatch(context), child: Text('Join Match')),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestore.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return Column(
            children: [
              Text('Email: ${data['email']}'),
              Text('Wallet: ₹${data['wallet']}'),
              Text('Role: ${data['role']}'),
            ],
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
        stream: firestore.collection('users').orderBy('wallet', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          final users = snapshot.data!.docs;
          return ListView(
            children: users.map((user) {
              final data = user.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['email']),
                trailing: Text('₹${data['wallet']}'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class SpinScreen extends StatelessWidget {
  final user = auth.currentUser;

  void spinAndAddMoney(BuildContext context) async {
    final doc = firestore.collection('users').doc(user!.uid);
    final snap = await doc.get();
    final data = snap.data() as Map<String, dynamic>;
    final lastSpin = (data['lastSpin'] as Timestamp?)?.toDate();
    final today = DateTime.now();

    if (lastSpin != null &&
        lastSpin.day == today.day &&
        lastSpin.month == today.month &&
        lastSpin.year == today.year) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('आज आपने पहले ही Spin कर लिया है')));
      return;
    }

    final reward = [0, 5, 10, 20, 0, 15][Random().nextInt(6)];
    final wallet = data['wallet'] ?? 0;

    await doc.update({
      'wallet': wallet + reward,
      'lastSpin': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You won ₹$reward!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Spin to Win')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => spinAndAddMoney(context),
          child: Text('Spin Now'),
        ),
      ),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('notifications').orderBy('time', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          final notifs = snapshot.data!.docs;
          return ListView(
            children: notifs.map((notif) {
              final data = notif.data() as Map<String, dynamic>;
              return ListTile(title: Text(data['message']));
            }).toList(),
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final controller = TextEditingController();
  final user = auth.currentUser!;

  void sendMessage() {
    if (controller.text.trim().isEmpty) return;
    firestore.collection('chat').add({
      'text': controller.text.trim(),
      'email': user.email,
      'time': Timestamp.now(),
    });
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('chat').orderBy('time', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final messages = snapshot.data!.docs;
                return ListView(
                  reverse: true,
                  children: messages.map((msg) {
                    final data = msg.data() as Map<String, dynamic>;
                    final time = (data['time'] as Timestamp?)?.toDate();
                    final formattedTime = time != null
                        ? TimeOfDay.fromDateTime(time).format(context)
                        : '';
                    return ListTile(
                      title: Text(data['text']),
                      subtitle: Text('${data['email']} • $formattedTime'),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(child: TextField(controller: controller, decoration: InputDecoration(hintText: 'Type message...'))),
              IconButton(onPressed: sendMessage, icon: Icon(Icons.send)),
            ],
          )
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(VictoryRoyaleApp());
}

class VictoryRoyaleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Victory Royale',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return HomePage();
        return AuthPage();
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  Future<void> registerOrLogin() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passController.text,
      );
    } catch (e) {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passController.text,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
        'email': emailController.text,
        'wallet': 0,
        'role': 'user',
        'lastSpin': '',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Victory Royale Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
          TextField(controller: passController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          ElevatedButton(onPressed: registerOrLogin, child: Text('Login / Register')),
        ]),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int wallet = 0;
  String role = 'user';
  String lastSpin = '';
  final msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    setState(() {
      wallet = doc['wallet'];
      role = doc['role'];
      lastSpin = doc['lastSpin'];
    });
  }

  Future<void> updateWallet(int amount) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'wallet': wallet + amount});
    fetchUserData();
  }

  Future<void> joinMatch(String matchId, int entryFee) async {
    if (wallet >= entryFee) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'wallet': wallet - entryFee});
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .collection('players')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({'joinedAt': Timestamp.now()});
      fetchUserData();
    }
  }

  Future<void> spinToWin() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (lastSpin == today) return;

    List<int> rewards = [5, 10, 15, 20];
    rewards.shuffle();
    int reward = rewards.first;

    await updateWallet(reward);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'lastSpin': today});
  }

  Future<void> sendMessage() async {
    if (msgController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('chat').add({
      'msg': msgController.text.trim(),
      'uid': FirebaseAuth.instance.currentUser!.uid,
      'time': Timestamp.now(),
    });
    msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Victory Royale'),
        actions: [
          IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(12),
        children: [
          Text('Wallet: ₹$wallet'),
          Text('Role: $role'),
          SizedBox(height: 10),
          ElevatedButton(onPressed: spinToWin, child: Text('Spin to Win')),
          ElevatedButton(
            onPressed: () => updateWallet(50),
            child: Text('Add ₹50'),
          ),
          if (role == 'admin')
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('matches').add({
                  'title': 'New Match',
                  'entryFee': 20,
                  'time': Timestamp.now(),
                });
              },
              child: Text('Create Match (Admin)'),
            ),
          Divider(),
          Text('Matches'),
          StreamBuilder(
            stream: FirebaseFirestore.instance.collection('matches').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              var docs = snapshot.data!.docs;
              return Column(
                children: docs.map((doc) {
                  return ListTile(
                    title: Text(doc['title']),
                    subtitle: Text('Entry: ₹${doc['entryFee']}'),
                    trailing: ElevatedButton(
                      onPressed: () => joinMatch(doc.id, doc['entryFee']),
                      child: Text('Join'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          Divider(),
          Text('Leaderboard'),
          StreamBuilder(
            stream: FirebaseFirestore.instance.collection('users').orderBy('wallet', descending: true).limit(5).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              var users = snapshot.data!.docs;
              return Column(
                children: users.map((u) => ListTile(title: Text(u['email']), subtitle: Text('₹${u['wallet']}'))).toList(),
              );
            },
          ),
          Divider(),
          Text('Notifications'),
          StreamBuilder(
            stream: FirebaseFirestore.instance.collection('notifications').orderBy('time', descending: true).limit(5).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              var notifs = snapshot.data!.docs;
              return Column(
                children: notifs.map((n) => ListTile(title: Text(n['msg']))).toList(),
              );
            },
          ),
          Divider(),
          Text('Chat'),
          Container(
            height: 200,
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('chat').orderBy('time').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                var msgs = snapshot.data!.docs;
                return ListView(
                  children: msgs.map((m) {
                    var time = DateFormat('hh:mm a').format(m['time'].toDate());
                    return ListTile(
                      title: Text(m['msg']),
                      subtitle: Text(time),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(child: TextField(controller: msgController, decoration: InputDecoration(hintText: 'Message'))),
              IconButton(onPressed: sendMessage, icon: Icon(Icons.send)),
            ],
          ),
        ],
      ),
    );
  }
}

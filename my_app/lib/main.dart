import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';

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
      theme: ThemeData(primarySwatch: Colors.deepPurple),
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
        return LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;

  void authAction() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        await FirebaseFirestore.instance.collection('users').doc(user.user!.uid).set({
          'email': emailController.text.trim(),
          'wallet': 0,
          'role': 'user',
          'name': '',
          'photo': '',
          'lastSpin': '',
        });
      }
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
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            ElevatedButton(onPressed: authAction, child: Text(isLogin ? 'Login' : 'Register')),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? 'No account? Register' : 'Have account? Login'),
            )
          ],
        ),
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
  String name = '', photo = '';
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    DocumentSnapshot snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      wallet = snap['wallet'];
      name = snap['name'] ?? '';
      photo = snap['photo'] ?? '';
    });
  }

  void addMoney(int amount) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'wallet': FieldValue.increment(amount)
    });
    loadUserData();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Victory Royale'), actions: [
        IconButton(onPressed: logout, icon: Icon(Icons.logout)),
      ]),
      body: Column(
        children: [
          ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(photo.isEmpty ? 'https://i.imgur.com/BoN9kdC.png' : photo)),
            title: Text(name.isEmpty ? 'No Name' : name),
            subtitle: Text('Wallet: ₹$wallet'),
            trailing: ElevatedButton(
              onPressed: () => addMoney(50),
              child: Text('Add ₹50'),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('matches').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                var matches = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    var match = matches[index];
                    bool isFull = match['players'].length >= match['maxPlayers'];
                    return Card(
                      child: ListTile(
                        title: Text('${match['type']} | ${match['mode']}'),
                        subtitle: Text('Entry: ₹${match['entryFee']} | Kill: ₹${match['perKill']}'),
                        trailing: isFull
                            ? Text('Full', style: TextStyle(color: Colors.red))
                            : ElevatedButton(
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

  void joinMatch(match) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    int wallet = snap['wallet'];
    int entryFee = match['entryFee'];

    if (wallet >= entryFee) {
      List players = match['players'];
      if (!players.contains(uid) && players.length < match['maxPlayers']) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'wallet': wallet - entryFee,
        });
        await FirebaseFirestore.instance.collection('matches').doc(match.id).update({
          'players': FieldValue.arrayUnion([uid]),
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not enough balance!')));
    }
  }

  void spin() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    DocumentSnapshot snap = await userRef.get();
    String lastSpin = snap['lastSpin'] ?? '';
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastSpin != today) {
      int reward = [5, 10, 15, 20, 25][Random().nextInt(5)];
      await userRef.update({
        'wallet': FieldValue.increment(reward),
        'lastSpin': today,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You won ₹$reward')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Already spun today')));
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    QuerySnapshot snap = await FirebaseFirestore.instance.collection('users').orderBy('wallet', descending: true).limit(10).get();
    return snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  void sendMessage(String msg) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    String time = DateFormat('hh:mm a').format(DateTime.now());
    await FirebaseFirestore.instance.collection('chat').add({
      'uid': uid,
      'msg': msg,
      'time': time,
    });
  }

  void reportUser(String matchId, String category, String reason) async {
    await FirebaseFirestore.instance.collection('reports').add({
      'matchId': matchId,
      'category': category,
      'reason': reason,
      'reporter': FirebaseAuth.instance.currentUser!.uid,
      'timestamp': DateTime.now(),
    });
  }

  void createMatch({required String type, required String mode}) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (snap['role'] == 'admin') {
      int entryFee = 0, perKill = 0, prize = 0;
      if (type == 'BR') {
        entryFee = 20; perKill = 10; prize = 100;
      } else if (type == 'CS') {
        entryFee = 15; perKill = 8; prize = 70;
      }

      await FirebaseFirestore.instance.collection('matches').add({
        'type': type,
        'mode': mode,
        'entryFee': entryFee,
        'perKill': perKill,
        'prize': prize,
        'players': [],
        'maxPlayers': 4,
      });
    }
  }

  void uploadResult(String matchId, List<Map> winners) async {
    for (var winner in winners) {
      await FirebaseFirestore.instance.collection('users').doc(winner['uid']).update({
        'wallet': FieldValue.increment(winner['reward']),
      });});
    await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
      'status': 'completed',
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Match result uploaded')));
  }

  void submitKill(String matchId, int kills) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    int perKillReward = 10;  // Example reward per kill, yeh tum apne match ke hisaab se set kar sakte ho
    int totalReward = kills * perKillReward;

    await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
      'players': FieldValue.arrayUnion([{
        'uid': uid,
        'kills': kills,
        'totalReward': totalReward,
      }]),
    });

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'wallet': FieldValue.increment(totalReward),
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kills submitted aur reward add kiya gaya')));
  }
}

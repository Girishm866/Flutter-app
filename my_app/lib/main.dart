// Victory Royale - main.dart (All Features Included)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Victory Royale',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasData) {
          return HomeScreen();
        }
        return LoginPage();
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController email = TextEditingController();
  final TextEditingController pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Victory Royale Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: email, decoration: InputDecoration(labelText: 'Email')),
          TextField(controller: pass, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text, password: pass.text)
                    .catchError((e) async {
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.text, password: pass.text);
                  FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).set({
                    'email': email.text,
                    'wallet': 0,
                    'name': '',
                    'photo': '',
                    'role': 'user'
                  });
                });
              },
              child: Text("Login/Register"))
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
      appBar: AppBar(title: Text("Victory Royale"), actions: [
        IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: Icon(Icons.logout))
      ]),
      body: ListView(
        children: [
          ListTile(title: Text("Profile"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage()))),
          ListTile(title: Text("Matches"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchList()))),
          ListTile(title: Text("Leaderboard"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardPage()))),
        ],
      ),
    );
  }
}

// Profile Page with Edit Option
class ProfilePage extends StatelessWidget {
  final TextEditingController name = TextEditingController();
  final TextEditingController photo = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          var data = snapshot.data!.data() as Map;
          name.text = data['name'];
          photo.text = data['photo'];
          return Column(
            children: [
              Text("Wallet: ₹${data['wallet']}", style: TextStyle(fontSize: 18)),
              TextField(controller: name, decoration: InputDecoration(labelText: 'Name')),
              TextField(controller: photo, decoration: InputDecoration(labelText: 'Photo URL')),
              ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                      'name': name.text,
                      'photo': photo.text
                    });
                  },
                  child: Text("Save"))
            ],
          );
        },
      ),
    );
  }
}

// Match List with Join + Submit Kills + Match Full Check
class MatchList extends StatelessWidget {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  void showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails('id', 'channel', importance: Importance.max);
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Matches")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('matches').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          var docs = snapshot.data!.docs;
          return ListView(
            children: docs.map((doc) {
              var data = doc.data() as Map;
              bool isFull = (data['joined'] ?? []).length >= data['max'] ?? 100;
              return ListTile(
                title: Text(data['title']),
                subtitle: Text("Prize: ₹${data['prize']}, Entry: ₹${data['entry']}"),
                trailing: ElevatedButton(
                  onPressed: isFull
                      ? null
                      : () async {
                          var user = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                          int wallet = user['wallet'];
                          if (wallet >= data['entry']) {
                            await FirebaseFirestore.instance.collection('matches').doc(doc.id).update({
                              'joined': FieldValue.arrayUnion([uid])
                            });
                            await FirebaseFirestore.instance.collection('users').doc(uid).update({
                              'wallet': wallet - data['entry']
                            });
                            showNotification("Match Joined", "You've joined ${data['title']}");
                          }
                        },
                  child: Text("Join"),
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetail(doc.id))),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class MatchDetail extends StatelessWidget {
  final String matchId;
  final killController = TextEditingController();
  MatchDetail(this.matchId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Match Detail")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('matches').doc(matchId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          var data = snapshot.data!.data() as Map;
          return Column(
            children: [
              Text("Title: ${data['title']}", style: TextStyle(fontSize: 18)),
              Text("Prize: ₹${data['prize']}, Entry: ₹${data['entry']}", style: TextStyle(fontSize: 16)),
              TextField(controller: killController, decoration: InputDecoration(labelText: 'Your Kills'), keyboardType: TextInputType.number),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('matches').doc(matchId).collection('kills').doc(FirebaseAuth.instance.currentUser!.uid).set({
                    'kills': int.parse(killController.text)
                  });
                },
                child: Text("Submit Kills"),
              )
            ],
          );
        },
      ),
    );
  }
}

class LeaderboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Leaderboard")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('wallet', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          var docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var user = docs[index].data() as Map;
              return ListTile(
                title: Text(user['name'] ?? ''),
                subtitle: Text(user['email']),
                trailing: Text("₹${user['wallet']}"),
              );
            },
          );
        },
      ),
    );
  }
}

// Admin Match Result Upload + Prize
class AdminPanel extends StatelessWidget {
  final TextEditingController winner = TextEditingController();
  final TextEditingController prize = TextEditingController();
  final TextEditingController matchId = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Panel")),
      body: Column(
        children: [
          TextField(controller: matchId, decoration: InputDecoration(labelText: 'Match ID')),
          TextField(controller: winner, decoration: InputDecoration(labelText: 'Winner UID')),
          TextField(controller: prize, decoration: InputDecoration(labelText: 'Prize Amount')),
          ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(winner.text).update({
                  'wallet': FieldValue.increment(int.parse(prize.text))
                });
                flutterLocalNotificationsPlugin.show(0, "You Won!", "You've won ₹${prize.text}", NotificationDetails(android: AndroidNotificationDetails('id', 'Victory')));
              },
              child: Text("Upload Result"))
        ],
      ),
    );
  }
}

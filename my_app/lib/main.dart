import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tournament App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FirebaseAuth.instance.currentUser == null
          ? AuthScreen()
          : UserProfileScreen(),
    );
  }
}

// ===================== AUTH SCREEN =====================
class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;

  Future<void> createUserInFirestore(User user) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();
    if (!docSnapshot.exists) {
      await userDoc.set({'email': user.email, 'wallet': 100});
    }
  }

  Future<void> _submit() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await createUserInFirestore(userCredential.user!);
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: Text(isLogin ? 'Login' : 'Register')),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? 'Create account' : 'Already have account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== USER PROFILE SCREEN =====================
class UserProfileScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  Future<int> getJoinedMatchesCount(String uid) async {
    final matchesSnapshot = await FirebaseFirestore.instance.collection('matches').get();
    int count = 0;
    for (var match in matchesSnapshot.docs) {
      final joinedUsers = match.data()['joinedUsers'] ?? [];
      if (joinedUsers.contains(uid)) count++;
    }
    return count;
  }

  Future<int> getWalletBalance(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data()?['wallet'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;
    final email = user?.email ?? 'No Email';

    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: FutureBuilder(
        future: Future.wait([
          getJoinedMatchesCount(uid!),
          getWalletBalance(uid),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final matchesCount = snapshot.data?[0] ?? 0;
          final walletBalance = snapshot.data?[1] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: $email', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Matches Joined: $matchesCount', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Wallet Balance: ₹$walletBalance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MatchListScreen(),
                    ));
                  },
                  child: Text('View All Matches'),
                ),
                Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(context, MaterialPageRoute(
                        builder: (_) => AuthScreen(),
                      ));
                    },
                    child: Text('Logout'),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===================== MATCH LIST SCREEN =====================
class MatchListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('All Matches')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('matches').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final matches = snapshot.data!.docs;

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final data = match.data();
              return ListTile(
                title: Text(data['title'] ?? 'No Title'),
                subtitle: Text('Entry Fee: ₹${data['entryFee'] ?? 0} | Slots: ${data['slots'] ?? 0}'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MatchDetailsScreen(matchId: match.id),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ===================== MATCH DETAILS SCREEN =====================
class MatchDetailsScreen extends StatelessWidget {
  final String matchId;
  MatchDetailsScreen({required this.matchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Match Details')),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection('matches').doc(matchId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data()!;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title: ${data['title']}', style: TextStyle(fontSize: 22)),
                SizedBox(height: 10),
                Text('Entry Fee: ₹${data['entryFee']}'),
                SizedBox(height: 10),
                Text('Total Slots: ${data['slots']}'),
                SizedBox(height: 10),
                Text('Joined: ${(data['joinedUsers'] as List?)?.length ?? 0}'),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => JoinMatchScreen(matchId: matchId),
                    ));
                  },
                  child: Text('Join This Match'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===================== JOIN MATCH SCREEN =====================
class JoinMatchScreen extends StatelessWidget {
  final String matchId;
  final user = FirebaseAuth.instance.currentUser;

  JoinMatchScreen({required this.matchId});

  Future<void> joinMatch(BuildContext context) async {
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Match')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => joinMatch(context),
          child: Text('Confirm Join'),
        ),
      ),
    );
  }
}

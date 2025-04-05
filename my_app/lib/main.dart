// FULL main.dart with all features including leaderboard

import 'package:flutter/material.dart'; import 'package:firebase_core/firebase_core.dart'; import 'package:firebase_auth/firebase_auth.dart'; import 'package:cloud_firestore/cloud_firestore.dart';

void main() async { WidgetsFlutterBinding.ensureInitialized(); await Firebase.initializeApp(); runApp(MaterialApp(home: AuthScreen())); }

class AuthScreen extends StatefulWidget { @override State<AuthScreen> createState() => _AuthScreenState(); }

class _AuthScreenState extends State<AuthScreen> { final emailController = TextEditingController(); final passwordController = TextEditingController(); bool isLogin = true;

Future<void> handleAuth() async { final email = emailController.text.trim(); final password = passwordController.text.trim(); final auth = FirebaseAuth.instance;

try {
  if (isLogin) {
    await auth.signInWithEmailAndPassword(email: email, password: password);
  } else {
    final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
    await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'wallet': 100
    });
  }
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
}

}

@override Widget build(BuildContext context) { return Scaffold( appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')), body: Padding( padding: const EdgeInsets.all(20), child: Column(children: [ TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')), TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true), SizedBox(height: 20), ElevatedButton(onPressed: handleAuth, child: Text(isLogin ? 'Login' : 'Register')), TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? 'Create Account' : 'Already have an account?')) ]), ), ); } }

class HomeScreen extends StatelessWidget { final user = FirebaseAuth.instance.currentUser;

@override Widget build(BuildContext context) { return Scaffold( appBar: AppBar(title: Text('Tournament App')), body: Column(children: [ StreamBuilder<DocumentSnapshot>( stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(), builder: (context, snapshot) { final data = snapshot.data?.data() as Map<String, dynamic>?; final wallet = data?['wallet'] ?? 0; return ListTile(title: Text('Welcome ${user!.email}'), subtitle: Text('Wallet: ₹$wallet')); }, ), Expanded( child: StreamBuilder<QuerySnapshot>( stream: FirebaseFirestore.instance.collection('matches').snapshots(), builder: (context, snapshot) { if (!snapshot.hasData) return Center(child: CircularProgressIndicator()); final matches = snapshot.data!.docs; return ListView.builder( itemCount: matches.length, itemBuilder: (context, index) { final match = matches[index]; return ListTile( title: Text(match['title']), subtitle: Text('Entry Fee: ₹${match['entryFee']}'), trailing: Text('Slots: ${match['slots']}'), onTap: () => Navigator.push(context, MaterialPageRoute( builder: () => MatchDetailsScreen(matchId: match.id))), ); }, ); }, ), ) ]), drawer: Drawer( child: ListView( children: [ DrawerHeader(child: Text(user!.email ?? '')), ListTile(title: Text('Create Match'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: () => CreateMatchScreen()))), ListTile(title: Text('Profile'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: () => ProfileScreen()))), ListTile(title: Text('Leaderboard'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: () => LeaderboardScreen()))), ListTile(title: Text('Logout'), onTap: () async { await FirebaseAuth.instance.signOut(); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthScreen())); }) ], ), ), ); } }

class CreateMatchScreen extends StatelessWidget { final titleController = TextEditingController(); final entryFeeController = TextEditingController(); final slotsController = TextEditingController();

Future<void> createMatch() async { await FirebaseFirestore.instance.collection('matches').add({ 'title': titleController.text.trim(), 'entryFee': int.parse(entryFeeController.text.trim()), 'slots': int.parse(slotsController.text.trim()), 'joinedUsers': [] }); }

@override Widget build(BuildContext context) { return Scaffold( appBar: AppBar(title: Text('Create Match')), body: Padding( padding: const EdgeInsets.all(20), child: Column(children: [ TextField(controller: titleController, decoration: InputDecoration(labelText: 'Match Title')), TextField(controller: entryFeeController, decoration: InputDecoration(labelText: 'Entry Fee'), keyboardType: TextInputType.number), TextField(controller: slotsController, decoration: InputDecoration(labelText: 'Total Slots'), keyboardType: TextInputType.number), SizedBox(height: 20), ElevatedButton(onPressed: () async { await createMatch(); Navigator.pop(context); }, child: Text('Create')) ]), ), ); } }

class MatchDetailsScreen extends StatefulWidget { final String matchId; MatchDetailsScreen({required this.matchId});

@override State<MatchDetailsScreen> createState() => _MatchDetailsScreenState(); }

class _MatchDetailsScreenState extends State<MatchDetailsScreen> { final user = FirebaseAuth.instance.currentUser; final TextEditingController winnerUidController = TextEditingController();

Future<void> declareWinner() async { final winnerUid = winnerUidController.text.trim(); final matchDoc = FirebaseFirestore.instance.collection('matches').doc(widget.matchId); final userDoc = FirebaseFirestore.instance.collection('users').doc(winnerUid);

await FirebaseFirestore.instance.runTransaction((transaction) async {
  final matchSnap = await transaction.get(matchDoc);
  final userSnap = await transaction.get(userDoc);

  if (!userSnap.exists) throw Exception("User not found");

  final currentBalance = userSnap['wallet'] ?? 0;
  final prize = 20;

  transaction.update(matchDoc, {'winnerUid': winnerUid});
  transaction.update(userDoc, {'wallet': currentBalance + prize});
});

ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Winner updated & prize sent!')));
winnerUidController.clear();

}

Future<void> joinMatch() async { final matchDoc = FirebaseFirestore.instance.collection('matches').doc(widget.matchId); final userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);

await FirebaseFirestore.instance.runTransaction((transaction) async {
  final matchSnap = await transaction.get(matchDoc);
  final userSnap = await transaction.get(userDoc);
  final joined = List.from(matchSnap['joinedUsers'] ?? []);

  if (joined.contains(user!.uid)) return;

  final wallet = userSnap['wallet'] ?? 0;
  final fee = matchSnap['entryFee'];
  if (wallet < fee) throw Exception("Not enough balance");

  joined.add(user!.uid);
  transaction.update(matchDoc, {'joinedUsers': joined});
  transaction.update(userDoc, {'wallet': wallet - fee});
});

ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joined Match')));

}

@override Widget build(BuildContext context) { return Scaffold( appBar: AppBar(title: Text('Match Details')), body: FutureBuilder<DocumentSnapshot>( future: FirebaseFirestore.instance.collection('matches').doc(widget.matchId).get(), builder: (context, snapshot) { if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

final data = snapshot.data!.data() as Map<String, dynamic>;
      final winnerUid = data['winnerUid'];

      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Title: ${data['title']}', style: TextStyle(fontSize: 22)),
          Text('Entry Fee: ₹${data['entryFee']}'),
          Text('Slots: ${data['slots']}'),
          Text('Joined: ${(data['joinedUsers'] as List?)?.length ?? 0}'),
          SizedBox(height: 20),
          if (winnerUid != null)
            Text('Winner: $winnerUid', style: TextStyle(color: Colors.green))
          else if (user?.email == 'admin@gmail.com') ...[
            TextField(controller: winnerUidController, decoration: InputDecoration(labelText: 'Winner UID')),
            ElevatedButton(onPressed: declareWinner, child: Text('Declare Winner')),
          ],
          SizedBox(height: 20),
          ElevatedButton(onPressed: joinMatch, child: Text('Join Match'))
        ]),
      );
    },
  ),
);

} }

class ProfileScreen extends StatelessWidget { final user = FirebaseAuth.instance.currentUser;

@override Widget build(BuildContext context) { return Scaffold( appBar: AppBar(title: Text('Profile')), body: StreamBuilder<DocumentSnapshot>( stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(), builder: (context, snapshot) { final data = snapshot.data?.data() as Map<String, dynamic>?; final wallet = data?['wallet'] ?? 0; return Center( child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Text('Email: ${user!.email}'), Text('Wallet: ₹$wallet'), ]), ); }, ), ); } }

class LeaderboardScreen extends StatelessWidget { const LeaderboardScreen({super.key});

@override Widget build(BuildContext context) { return Scaffold( appBar: AppBar(title: Text('Leaderboard')), body: StreamBuilder<QuerySnapshot>( stream: FirebaseFirestore.instance.collection('users').orderBy('wallet', descending: true).limit(10).snapshots(), builder: (context, snapshot) { if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

final users = snapshot.data!.docs;
      return ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(child: Text('#${index + 1}')),
            title: Text(user['email'] ?? 'No Email'),
            trailing: Text('₹${user['wallet'] ?? 0}'),
          );
        },
      );
    },
  ),
);

} }


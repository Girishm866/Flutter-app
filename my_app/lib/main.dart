import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          'wallet': 100
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Amount must be between ₹5 and ₹500")));
      return;
    }

    final doc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final current = snap['wallet'] ?? 0;
      tx.update(doc, {'wallet': current + amount});
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('₹$amount added to wallet')));
    amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Money')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: amountController, decoration: InputDecoration(labelText: 'Enter Amount (₹5 - ₹500)'), keyboardType: TextInputType.number),
          SizedBox(height: 20),
          ElevatedButton(onPressed: addMoney, child: Text('Add to Wallet'))
        ]),
      ),
    );
  }
}

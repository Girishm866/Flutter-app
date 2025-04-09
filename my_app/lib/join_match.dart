import 'package:flutter/material.dart'; import 'package:cloud_firestore/cloud_firestore.dart'; import 'package:firebase_auth/firebase_auth.dart'; import 'package:intl/intl.dart';

class MatchType { final String category; final String mode; final int entryFee; final int? perKillReward; final List<int>? topPrizes; final int? perPlayerPrize;

MatchType({ required this.category, required this.mode, required this.entryFee, this.perKillReward, this.topPrizes, this.perPlayerPrize, }); }

List<MatchType> matchTypes = [ MatchType(category: 'BR', mode: '1v1', entryFee: 10, perKillReward: 7, topPrizes: [20, 10, 5]), MatchType(category: 'BR', mode: '2v2', entryFee: 10, perKillReward: 7, topPrizes: [20, 10, 5]), MatchType(category: 'CS', mode: '1v1', entryFee: 20, perPlayerPrize: 30), MatchType(category: 'CS', mode: '2v2', entryFee: 20, perPlayerPrize: 30), MatchType(category: 'CS', mode: '4v4', entryFee: 20, perPlayerPrize: 30), MatchType(category: 'Lone Wolf', mode: '1v1', entryFee: 20, perPlayerPrize: 30), MatchType(category: 'Lone Wolf', mode: '2v2', entryFee: 20, perPlayerPrize: 30), MatchType(category: 'Zone Survival', mode: 'Top 10', entryFee: 20, topPrizes: [50, 40, 30, 25, 20, 15, 10, 10, 10, 10]), ];

class JoinMatchScreen extends StatefulWidget { @override _JoinMatchScreenState createState() => _JoinMatchScreenState(); }

class _JoinMatchScreenState extends State<JoinMatchScreen> { String userId = FirebaseAuth.instance.currentUser!.uid;

Future<void> joinMatch(DocumentSnapshot match) async { final category = match['category']; final mode = match['mode']; final matchType = matchTypes.firstWhere( (m) => m.category == category && m.mode == mode, orElse: () => MatchType(category: '', mode: '', entryFee: 0), ); final entryFee = matchType.entryFee;

final walletRef = FirebaseFirestore.instance.collection('users').doc(userId);
final walletSnap = await walletRef.get();
final currentBalance = walletSnap.data()?['wallet'] ?? 0;

final participantDoc = await FirebaseFirestore.instance
    .collection('matches')
    .doc(match.id)
    .collection('participants')
    .doc(userId)
    .get();

if (participantDoc.exists) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('You have already joined this match.')),
  );
  return;
}

if (currentBalance >= entryFee) {
  await walletRef.update({'wallet': currentBalance - entryFee});
  await FirebaseFirestore.instance
      .collection('matches')
      .doc(match.id)
      .collection('participants')
      .doc(userId)
      .set({'joinedAt': Timestamp.now()});

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Match joined successfully!')),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Not enough balance in wallet.')),
  );
}

}

void openMatchDetails(DocumentSnapshot match) { Navigator.push( context, MaterialPageRoute( builder: (context) => MatchDetailsScreen(match: match), ), ); }

@override Widget build(BuildContext context) { return Scaffold( appBar: AppBar(title: Text('Join Match')), body: StreamBuilder<QuerySnapshot>( stream: FirebaseFirestore.instance .collection('matches') .orderBy('createdAt', descending: true) .snapshots(), builder: (context, snapshot) { if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

final matches = snapshot.data!.docs;

      return ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          final category = match['category'];
          final mode = match['mode'];

          final matchType = matchTypes.firstWhere(
            (m) => m.category == category && m.mode == mode,
            orElse: () => MatchType(category: '', mode: '', entryFee: 0),
          );

          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text(match['matchName'] ?? 'Match'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Entry Fee: ₹${matchType.entryFee}'),
                  if (matchType.perKillReward != null)
                    Text('Per Kill: ₹${matchType.perKillReward}'),
                  if (matchType.perPlayerPrize != null)
                    Text('Prize: ₹${matchType.perPlayerPrize} per player'),
                  if (matchType.topPrizes != null)
                    Text('Top Prizes: ${matchType.topPrizes!.join(', ')}'),
                  Text('Game Mode: ${match['gameMode']}'),
                ],
              ),
              trailing: ElevatedButton(
                child: Text('Join'),
                onPressed: () => joinMatch(match),
              ),
              onTap: () => openMatchDetails(match),
            ),
          );
        },
      );
    },
  ),
);

} }

class MatchDetailsScreen extends StatelessWidget { final DocumentSnapshot match;

MatchDetailsScreen({required this.match});

@override Widget build(BuildContext context) { return Scaffold( appBar: AppBar(title: Text('${match['matchName']} Details')), body: Padding( padding: const EdgeInsets.all(16.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text('Entry Fee: ₹${match['entryFee']}'), Text('Prize Pool: ₹${match['prizePool']}'), Text('Game Mode: ${match['gameMode']}'), SizedBox(height: 20), Text('Joined Players:', style: TextStyle(fontWeight: FontWeight.bold)), Expanded( child: StreamBuilder<QuerySnapshot>( stream: FirebaseFirestore.instance .collection('matches') .doc(match.id) .collection('participants') .snapshots(), builder: (context, snapshot) { if (!snapshot.hasData) return Center(child: CircularProgressIndicator()); final participants = snapshot.data!.docs;

if (participants.isEmpty) {
                return Text('No players joined yet.');
              }

              return ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final joinedTime = DateFormat('dd MMM yyyy, hh:mm a')
                      .format(participants[index]['joinedAt'].toDate());
                  return ListTile(
                    title: Text('Player ${index + 1}'),
                    subtitle: Text('Joined at: $joinedTime'),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  ),
);

} }

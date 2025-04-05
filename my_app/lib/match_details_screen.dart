class MatchDetailsScreen extends StatefulWidget {
  final String matchId;
  MatchDetailsScreen({required this.matchId});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController winnerUidController = TextEditingController();

  Future<void> declareWinner() async {
    final winnerUid = winnerUidController.text.trim();
    final matchDoc = FirebaseFirestore.instance.collection('matches').doc(widget.matchId);
    final userDoc = FirebaseFirestore.instance.collection('users').doc(winnerUid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final matchSnap = await transaction.get(matchDoc);
      final userSnap = await transaction.get(userDoc);

      if (!userSnap.exists) throw Exception("User not found");

      final currentBalance = userSnap['wallet'] ?? 0;
      final prize = 20;

      transaction.update(matchDoc, {'winnerUid': winnerUid});
      transaction.update(userDoc, {'wallet': currentBalance + prize});
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Winner updated & prize sent!')),
    );
    winnerUidController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Match Details')),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection('matches').doc(widget.matchId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data()!;
          final winnerUid = data['winnerUid'];

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title: ${data['title']}', style: TextStyle(fontSize: 22)),
                SizedBox(height: 10),
                Text('Entry Fee: ₹${data['entryFee']}'),
                Text('Total Slots: ${data['slots']}'),
                Text('Joined: ${(data['joinedUsers'] as List?)?.length ?? 0}'),
                SizedBox(height: 20),

                // Winner Show or Declare
                if (winnerUid != null)
                  Text('Winner: $winnerUid', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                else if (user?.email == 'admin@gmail.com') ...[
                  TextField(
                    controller: winnerUidController,
                    decoration: InputDecoration(labelText: 'Enter Winner UID'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: declareWinner,
                    child: Text('Declare Winner'),
                  ),
                ],

                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => JoinMatchScreen(matchId: widget.matchId)),
                    );
                  },
                  child: Text('Join This Match'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

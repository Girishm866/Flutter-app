import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  bool isSendEnabled = false;

  @override
  void initState() {
    super.initState();
    messageController.addListener(() {
      setState(() {
        isSendEnabled = messageController.text.trim().isNotEmpty;
      });
    });
  }

  void sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (messageController.text.trim().isEmpty || user == null) return;

    await FirebaseFirestore.instance.collection('messages').add({
      'text': messageController.text.trim(),
      'senderId': user.uid,
      'timestamp': Timestamp.now(),
    });

    messageController.clear();
  }

  String formatTimestamp(Timestamp timestamp) {
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Global Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final text = msg['text'] ?? '';
                    final sender = msg['senderId'] ?? 'Unknown';
                    final time = formatTimestamp(msg['timestamp']);
                    final isMe = sender == FirebaseAuth.instance.currentUser?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(text, style: TextStyle(fontSize: 16)),
                            SizedBox(height: 4),
                            Text('$time', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: isSendEnabled ? sendMessage : null,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

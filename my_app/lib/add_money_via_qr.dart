import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddMoneyViaQRScreen extends StatefulWidget {
  @override
  _AddMoneyViaQRScreenState createState() => _AddMoneyViaQRScreenState();
}

class _AddMoneyViaQRScreenState extends State<AddMoneyViaQRScreen> {
  int selectedAmount = 0;

  final qrImageUrl = 'https://your-qr-image-url.jpg'; // यहाँ अपना QR लिंक डालो
  final upiId = 'gj990206@ybl';

  void submitRequest() async {
    if (selectedAmount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an amount')));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'paymentPending': true,
        'amountRequested': selectedAmount,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment request sent. Waiting for admin approval.')));
      setState(() {
        selectedAmount = 0;
      });
    }
  }

  void copyUPI() {
    Clipboard.setData(ClipboardData(text: upiId));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('UPI ID copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Money via QR')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Image.network(qrImageUrl, height: 200),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(upiId, style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(icon: Icon(Icons.copy), onPressed: copyUPI),
              ],
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: [5, 10, 20, 50, 100].map((amount) {
                return ChoiceChip(
                  label: Text('₹$amount'),
                  selected: selectedAmount == amount,
                  onSelected: (_) => setState(() => selectedAmount = amount),
                );
              }).toList(),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: submitRequest,
              child: Text('I Have Paid'),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }
}

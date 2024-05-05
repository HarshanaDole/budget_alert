import 'package:budget_alert/sms_reader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String? userID;
final Map<String, DocumentSnapshot> _bankDataCache = {};
bool permissionDialogShown = false;

Future<DocumentSnapshot> getBankData(String bankName) async {
  if (_bankDataCache.containsKey(bankName)) {
    return _bankDataCache[bankName]!;
  } else {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('banks')
        .where('name', isEqualTo: bankName)
        .get()
        .then((value) => value.docs.first);
    _bankDataCache[bankName] = snapshot;
    return snapshot;
  }
}

Future<bool> checkPermission(BuildContext context) async {
  final status = await Permission.sms.status;
  if (!status.isGranted) {
    // Show dialog and wait for user interaction
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This app requires access to your SMS messages to scan for transaction information. This information is used to provide financial insights and manage transactions.',
            ),
            SizedBox(height: 16),
            Text(
              'Would you like to grant access to your SMS messages?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Permission.sms.request();
              Navigator.pop(context, true);
            },
            child: Text('Agree'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text('Skip'),
          ),
        ],
      ),
    );
    permissionDialogShown = true;
    return result ?? false;
  } else {
    return true;
  }
}

Future<Map<String, Set<dynamic>>> fetchSenderIds() async {
  Map<String, Set<dynamic>> senderIdsAndDigits = {
    'senderIds': <String>{},
    'accountNums': <String>{},
    'lastCardNums': <String>{},
  };
  userID = FirebaseAuth.instance.currentUser?.uid;
  if (userID != null) {
    QuerySnapshot accountSnapshot = await FirebaseFirestore.instance
        .collection('accounts')
        .where('uid', isEqualTo: userID)
        .get();

    List<Map<String, dynamic>> accountsData = accountSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    for (Map<String, dynamic> accountData in accountsData) {
      String bankName = accountData['bankName'] as String;
      String? accountNumber = (accountData['accountNumber'] ?? '').toString();
      String? cardNumber = (accountData['cardNumber'] ?? '').toString();

      // get senderId from banks collection based on bankName
      DocumentSnapshot bankSnapshot = await getBankData(bankName);
      if (bankSnapshot.exists) {
        if (bankName == 'Cash') {
          continue;
        }
        Map<String, dynamic>? data =
            bankSnapshot.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('senderId')) {
          String senderId = data['senderId'] as String;
          senderIdsAndDigits['senderIds']!.add(senderId);
          senderIdsAndDigits['accountNums']!.add(accountNumber);
          senderIdsAndDigits['lastCardNums']!.add(cardNumber);
        } else {
          print('Warning: No senderId found for bank $bankName');
        }
      }
    }
  }
  return senderIdsAndDigits;
}

Future<void> readMessages(context, List<String> senderIds,
    Set<String> accountNums, Set<String> lastCardNums, userID) async {
  final permissionGranted = await checkPermission(context);
  if (permissionGranted) {
    try {
      await SmsReader.readAndSendMessages(
          senderIds, accountNums, lastCardNums, userID);
    } catch (e) {
      print('Error reading and sending SMS: $e');
    }
  }
}

Future<void> rescan(BuildContext context, List<String> senderIds,
    Set<String> accountNums, Set<String> lastCardNums, String? userID) async {
  final permissionGranted = await checkPermission(context);
  if (permissionGranted) {
    readMessages(context, senderIds, accountNums, lastCardNums, userID);
  }
}

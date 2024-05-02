import 'package:budget_alert/sms_reader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String? userID;
final Map<String, DocumentSnapshot> _bankDataCache = {};

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

Future<void> checkPermission() async {
  final status = await Permission.sms.status;
  if (!status.isGranted) {
    await Permission.sms.request();
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

Future<void> readMessages(List<String> senderIds, Set<String> accountNums,
    Set<String> lastCardNums, userID) async {
  try {
    await SmsReader.readAndSendMessages(
        senderIds, accountNums, lastCardNums, userID);
  } catch (e) {
    print('Error reading and sending SMS: $e');
  }
}

Future<void> rescan(BuildContext context, List<String> senderIds,
    Set<String> accountNums, Set<String> lastCardNums, String? userID) async {
  final permissionStatus = await Permission.sms.status;
  if (permissionStatus.isGranted) {
    readMessages(senderIds, accountNums, lastCardNums, userID);
  } else {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
            'Please grant SMS permission from settings to rescan messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

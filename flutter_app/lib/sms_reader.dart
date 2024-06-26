// import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
// ignore_for_file: avoid_print, prefer_collection_literals

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:telephony/telephony.dart';

final Telephony telephony = Telephony.instance;

class SmsReader {
  static void listenAndSendMessages(List<String> senderIds,
      Set<String> accountNums, Set<String> lastCardNums, String? uid) {
    // register listener for incoming SMS messages
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        // handle each new message
        if (senderIds.contains(message.address)) {
          if (isTransactionMessage(
              message, message.address!, accountNums, lastCardNums)) {
            await sendToBackend(message, message.address!, uid);
          }
        }
      },
      onBackgroundMessage:
          backgroundMessageHandler, // handle messages in background
    );
  }

  static Future<void> backgroundMessageHandler(SmsMessage message) async {
    print("Background Message: ${message.body}");
    print("Syncing message data with backend...");
  }

  static Future<void> readAndSendMessages(List<String> senderIds,
      Set<String> accountNums, Set<String> lastCardNums, String? uid) async {
    try {
      // iterate over each selected senderId
      for (String senderId in senderIds) {
        // read messages for the current senderId
        List<SmsMessage> messages = await telephony.getInboxSms(
          columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
          filter: SmsFilter.where(SmsColumn.ADDRESS).equals(senderId),
        );

        // filter out non transaction messages
        messages = messages
            .where((message) => isTransactionMessage(
                  message,
                  senderId,
                  accountNums,
                  lastCardNums,
                ))
            .toList();

        //limit to 50 for testing
        messages = messages.take(50).toList();

        //send each message to the backend
        for (SmsMessage message in messages) {
          await sendToBackend(message, senderId, uid);
        }
      }
    } catch (e) {
      print('Error reading and sending SMS: $e');
    }
  }

  static Set<String> getLastFourDigits(Set<String> accountNums) {
    Set<String> lastFourDigits = Set<String>();

    for (String accountNum in accountNums) {
      if (accountNum.length >= 4) {
        String lastFour = accountNum.substring(accountNum.length - 4);
        lastFourDigits.add(lastFour);
      }
    }

    return lastFourDigits;
  }

  static bool isTransactionMessage(SmsMessage message, String senderId,
      Set<String> accountNums, Set<String> lastCardNums) {
    // print(accountNums);
    // print(lastCardNums);
    Set<String> lastFourDigits = getLastFourDigits(accountNums);
    // print(lastFourDigits);

    String? body = message.body;
    RegExp regex = RegExp(
        r'[\d*X#]+(\d{4})'); // match last 4 digits of acc or card numbers

    if (body != null) {
      if (senderId == 'COMBANK') {
        Iterable<String> matches =
            regex.allMatches(body).map((match) => match.group(1)!).toList();

        for (String match in matches) {
          // check if the last four digits match any user-defined account number or card number
          if (lastFourDigits.contains(match) || lastCardNums.contains(match)) {
            // check if the message contains transaction-related keywords
            if (RegExp('Purchase at').hasMatch(body)) return true;
            if (RegExp('Credit for').hasMatch(body)) return true;
            if (RegExp('CRC Deposit').hasMatch(body)) return true;
            if (RegExp('CRM Deposit').hasMatch(body)) return true;
            if (RegExp('Withdrawal at').hasMatch(body)) return true;
          }
        }
      }
      // if (senderId == 'NSB') {
      //   if (body.contains('AC')) return true;
      // }
    }
    return false;
  }

  static Future<void> sendToBackend(
      SmsMessage message, String senderId, String? uid) async {
    // print('Sending message to backend: ${message.body}');

    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(message.date!);

    String date = dateTime.toIso8601String();

    Map<String, dynamic> requestBody = {
      'smsBody': message.body,
      'bank': senderId,
      'date': date,
      'uid': uid,
    };

    Uri uri = Uri.parse('http://3.111.149.246:8000/receive_sms');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('SMS message sent to backend successfully: $requestBody');
      } else {
        print('Failed to send SMS message to backend');
      }
    } catch (e) {
      print('Error sending SMS message to backend: $e');
    }
  }
}

import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SmsReader {
  static Future<void> readAndSendMessages(List<String> senderIds,
      Set<String> accountNums, Set<String> lastCardNums) async {
    SmsQuery query = SmsQuery();

    try {
      // iterate over each selected senderId
      for (String senderId in senderIds) {
        // read messages for the current senderId
        List<SmsMessage> messages = await query.querySms(
          address: senderId,
          kinds: [SmsQueryKind.inbox],
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
          await sendToBackend(message, senderId);
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
    print(lastFourDigits);

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
    }
    return false;
  }

  static Future<void> sendToBackend(SmsMessage message, String senderId) async {
    // print('Sending message to backend: ${message.body}');

    Map<String, dynamic> requestBody = {
      'smsBody': message.body,
      'bank': senderId,
      'date': message.date!.toIso8601String(),
    };

    Uri uri = Uri.parse('http://192.168.8.176:5000/receive_sms');

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

// sms_reader.dart
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';

class SmsReader {
  static Future<void> readAndSendMessages(List<String> senderIds) async {
    SmsQuery query = SmsQuery();

    try {
      // Iterate over each selected account
      for (String senderId in senderIds) {
        // Read messages for the current account
        List<SmsMessage> messages = await query.querySms(
          address: senderId,
          kinds: [SmsQueryKind.inbox],
        );

        // Send each message to the backend
        for (SmsMessage message in messages) {
          await sendToBackend(message);
        }
      }
    } catch (e) {
      print('Error reading and sending SMS: $e');
    }
  }

  static Future<void> sendToBackend(SmsMessage message) async {
    // Implement your logic to send the message to the backend here
    print('Sending message to backend: ${message.body}');
    // You can make HTTP requests or use any other method to send the message
  }
}

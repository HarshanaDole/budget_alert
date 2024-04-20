import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SmsReaderPage(),
    );
  }
}

class SmsReaderPage extends StatefulWidget {
  @override
  _SmsReaderPageState createState() => _SmsReaderPageState();
}

class _SmsReaderPageState extends State<SmsReaderPage> {
  late List<SmsMessage> _messages;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _readSms();
  }

  Future<void> _readSms() async {
    try {
      List<SmsMessage> allMessages = await SmsQuery().querySms(
        address: "COMBANK", // Filter by sender ID
        kinds: [SmsQueryKind.inbox], // Fetch only received messages
      );

      // Sort messages by date
      allMessages.sort(
          (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));

      // Get the latest message
      _messages = allMessages.isNotEmpty ? [allMessages.first] : [];
    } catch (e) {
      print('Error reading SMS: $e');
      _messages = [];
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reading SMS...'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? Center(child: Text('No messages found from COMBANK'))
              : LastMessagePage(message: _messages.first),
    );
  }
}

class LastMessagePage extends StatelessWidget {
  final SmsMessage message;

  const LastMessagePage({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Last COMBANK Message'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message: ${message.body}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'From: ${message.address}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:v1/add_account.dart';
import 'package:v1/add_transaction.dart';
import 'package:v1/login.dart';
import 'package:v1/models/account_model.dart';
import 'package:v1/registration.dart';
import 'components/app_colors.dart';
import 'models/transaction_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  User? user = FirebaseAuth.instance.currentUser;
  Widget homeScreen = user != null ? Home() : LoginPage();

  runApp(MaterialApp(
    home: homeScreen,
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Stream<List<TransactionDetails>> transactions;
  late Stream<List<AccountDetails>> accounts;
  late StreamController<List<TransactionDetails>> _transactionStreamController;

  String selectedAccount = '0';

  @override
  void initState() {
    super.initState();
    String? userID = FirebaseAuth.instance.currentUser?.uid;

    _transactionStreamController = StreamController<List<TransactionDetails>>();

    transactions = FirebaseFirestore.instance
        .collection('transactions')
        .where('account', isEqualTo: selectedAccount)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                TransactionDetails.fromMap(doc.data() as Map<String, dynamic>))
            .toList());

    accounts = FirebaseFirestore.instance
        .collection('accounts')
        .where('uid', isEqualTo: userID)
        .orderBy('accountNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountDetails.fromMap({
                  ...doc.data(),
                  'bankName': doc['bankName'],
                }))
            .toList());

    _fetchTransactions(selectedAccount);
  }

  @override
  void dispose() {
    _transactionStreamController.close();
    super.dispose();
  }

  void _fetchTransactions(String acccountNumber) {
    transactions = FirebaseFirestore.instance
        .collection('transactions')
        .where('account', isEqualTo: acccountNumber)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                TransactionDetails.fromMap(doc.data() as Map<String, dynamic>))
            .toList());

    transactions.listen((event) {
      _transactionStreamController.add(event);
    });
  }

  Future<DocumentSnapshot> getBankData(String bankName) {
    return FirebaseFirestore.instance
        .collection('banks')
        .where('name', isEqualTo: bankName)
        .get()
        .then((value) => value.docs.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BodyColor,
      appBar: AppBar(
        backgroundColor: AppColors.MainColor,
        foregroundColor: Colors.white,
        title: const Text('Budget Alert'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w300),
                        ),
                        Text(
                          'LKR 750,000.00',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.alarm,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.SubColor,
              ),
              child: Text('Menu'),
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginPage()));
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Wallet',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See All'),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: StreamBuilder<List<AccountDetails>>(
                stream: accounts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    List<AccountDetails>? accountList = snapshot.data;
                    if (accountList == null || accountList.isEmpty) {
                      return Text('No accounts found');
                    }
                    return Row(
                      children: [
                        for (var account in accountList)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedAccount =
                                    account.accountNumber.toString();
                              });
                              _fetchTransactions(selectedAccount);
                            },
                            child: FutureBuilder<DocumentSnapshot>(
                                future: getBankData(account.bankName),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    Map<String, dynamic> bankData =
                                        snapshot.data!.data()
                                            as Map<String, dynamic>;
                                    Color lightColor =
                                        _parseColor(bankData['lightColor']);

                                    return Container(
                                      height: 100,
                                      width: 150,
                                      margin: EdgeInsets.only(right: 8.0),
                                      decoration: BoxDecoration(
                                        color: lightColor,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 16.0, 8.0, 16.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Total Balance',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      Text(
                                                        'LKR ${account.balance}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                FutureBuilder<DocumentSnapshot>(
                                                    future: getBankData(
                                                        account.bankName),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot.hasError) {
                                                        return Icon(
                                                            Icons.error);
                                                      } else {
                                                        Map<String, dynamic>
                                                            bankData = snapshot
                                                                    .data!
                                                                    .data()
                                                                as Map<String,
                                                                    dynamic>;
                                                        Color darkColor =
                                                            _parseColor(bankData[
                                                                'darkColor']);

                                                        return CircleAvatar(
                                                          backgroundColor:
                                                              darkColor,
                                                          radius: 15,
                                                          child: Image.asset(
                                                            'assets/${bankData['logoUrl']}',
                                                            height: 15,
                                                            width: 15,
                                                            color: Colors.white,
                                                          ),
                                                        );
                                                      }
                                                    }),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  account.bankName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                }),
                          ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AddAccountPage()));
                          },
                          child: Container(
                            height: 100,
                            width: 150,
                            margin: EdgeInsets.only(right: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey
                                  .withOpacity(0.5), // Adjust color as needed
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add_circle,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See All'),
                ),
              ],
            ),
            const Row(
              children: [
                Text(
                  'Today',
                  style: TextStyle(color: AppColors.GreyText),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<List<TransactionDetails>>(
                stream: transactions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    List<TransactionDetails> transactionList =
                        snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: transactionList.length,
                      itemBuilder: (context, index) {
                        TransactionDetails transaction = transactionList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.description,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        transaction.date,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '-LKR ${transaction.amount}',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => AddTransactionPage()));
        },
        backgroundColor: AppColors.MainColor,
        shape: const CircleBorder(),
        child: const Text(
          '+',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    List<String> components = colorString.split(',');
    int r = int.parse(components[0]);
    int g = int.parse(components[1]);
    int b = int.parse(components[2]);
    double opacity = double.parse(components[3]);
    return Color.fromRGBO(r, g, b, opacity);
  }
}

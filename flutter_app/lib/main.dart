import 'dart:async';
import 'package:budget_alert/components/customDrawer.dart';
import 'package:budget_alert/components/message_utils.dart';
import 'package:budget_alert/edit_transaction.dart';
import 'package:budget_alert/test_sms_recieve.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:budget_alert/add_account.dart';
import 'package:budget_alert/add_transaction.dart';
import 'package:budget_alert/login.dart';
import 'package:budget_alert/models/account_model.dart';
import 'package:budget_alert/edit_account.dart';
import 'components/app_colors.dart';
import 'models/transaction_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';

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
  String? userID;
  late Stream<List<TransactionDetails>> transactions;
  late Stream<List<AccountDetails>> accounts;
  late StreamController<List<TransactionDetails>> _transactionStreamController;

  double totalBalance = 0.0;

  String selectedAccount = 'Cash';

  List<String> senderIds = [];
  Set<String> accountNums = {};
  Set<String> lastCardNums = {};

  bool permissionDialogShown = false;

  @override
  void initState() {
    super.initState();

    userID = FirebaseAuth.instance.currentUser?.uid;

    _transactionStreamController = StreamController<List<TransactionDetails>>();

    transactions = FirebaseFirestore.instance
        .collection('transactions')
        .where('uid', isEqualTo: userID)
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

    _fetchTransactions(selectedAccount, userID!);

    fetchSenderIds().then((senderIdsAndDigits) {
      print('$senderIdsAndDigits');
      senderIds =
          senderIdsAndDigits['senderIds']!.map((e) => e as String).toList();
      accountNums =
          senderIdsAndDigits['accountNums']!.map((e) => e as String).toSet();
      lastCardNums =
          senderIdsAndDigits['lastCardNums']!.map((e) => e as String).toSet();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        readMessages(context, senderIds, accountNums, lastCardNums, userID);
      });
    });

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (!permissionDialogShown) {
    //     checkPermission(context);
    //   }
    // });
  }

  @override
  void dispose() {
    _transactionStreamController.close();
    super.dispose();
  }

  Stream<double> getTotalBalanceStream() {
    return FirebaseFirestore.instance
        .collection('accounts')
        .where('uid', isEqualTo: userID)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.fold<double>(0.0, (previousValue, doc) {
        var balance = doc['balance'];
        if (balance is int) {
          return previousValue + balance.toDouble();
        } else if (balance is double) {
          return previousValue + balance;
        } else {
          return previousValue;
        }
      });
    });
  }

  void _fetchTransactions(String acccountNumber, String userID) {
    transactions = FirebaseFirestore.instance
        .collection('transactions')
        .where('uid', isEqualTo: userID)
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Balance',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w300),
                        ),
                        StreamBuilder<double>(
                          stream: getTotalBalanceStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              return Text(
                                'LKR ${snapshot.data!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            rescan(context, senderIds, accountNums,
                                lastCardNums, userID);
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 30,
                          ),
                          tooltip: 'Rescan',
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
      drawer: CustomDrawer(),
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
              padding: const EdgeInsets.only(left: 12.0),
              scrollDirection: Axis.horizontal,
              child: StreamBuilder<List<AccountDetails>>(
                stream: accounts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No accounts found');
                  } else {
                    List<AccountDetails> accountList = snapshot.data!;

                    return SizedBox(
                      height: 130,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (var account in accountList)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  print('Account: ${account.account}');
                                  selectedAccount = account.account;
                                  userID = account.uid;
                                });
                                _fetchTransactions(selectedAccount, userID!);
                              },
                              onLongPress: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Edit Account'),
                                      content: Text(
                                          'Would you like to edit this account?'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('Edit'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditAccountPage(
                                                        accountDetails:
                                                            account),
                                              ),
                                            );
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: FutureBuilder<DocumentSnapshot>(
                                  future: getBankData(account.bankName),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Container(
                                        width: 150,
                                        height: 100,
                                        margin:
                                            const EdgeInsets.only(right: 8.0),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    } else if (snapshot.data == null ||
                                        !snapshot.data!.exists) {
                                      return const Text('Bank data not found');
                                    } else {
                                      Map<String, dynamic> bankData =
                                          snapshot.data!.data()
                                              as Map<String, dynamic>;
                                      Color lightColor =
                                          _parseColor(bankData['lightColor']);

                                      return Container(
                                        height: 100,
                                        width: 150,
                                        margin:
                                            const EdgeInsets.only(right: 8.0),
                                        decoration: BoxDecoration(
                                          color: lightColor,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          boxShadow: [
                                            if (selectedAccount ==
                                                account.account)
                                              const BoxShadow(
                                                color: Colors.black,
                                                offset: Offset(3.0, 3.0),
                                                blurRadius: 8.0,
                                                spreadRadius: 1.0,
                                              ),
                                            if (selectedAccount ==
                                                account.account)
                                              const BoxShadow(
                                                color: Colors.white,
                                                offset: Offset(0.0, 0.0),
                                                blurRadius: 0,
                                                spreadRadius: 0,
                                              ),
                                          ],
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
                                                        const Text(
                                                          'Total Balance',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        Text(
                                                          'LKR ${account.balance}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  FutureBuilder<
                                                          DocumentSnapshot>(
                                                      future: getBankData(
                                                          account.bankName),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return const CircularProgressIndicator();
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return Text(
                                                              'Error: ${snapshot.error}');
                                                        } else if (!snapshot
                                                                .hasData ||
                                                            snapshot.data ==
                                                                null) {
                                                          return const Text(
                                                              'No data available');
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return const Icon(
                                                              Icons.error);
                                                        } else {
                                                          Map<String, dynamic>
                                                              bankData =
                                                              snapshot.data!
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
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          );
                                                        }
                                                      }),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  if (account.bankName ==
                                                      'Cash')
                                                    Text(
                                                      account.bankName,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  if (account.bankName !=
                                                      'Cash')
                                                    Text(
                                                      'AC - xxxx${account.accountNumber.toString().substring(account.accountNumber.toString().length - 4)}',
                                                      style: const TextStyle(
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
                              margin: const EdgeInsets.only(right: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add_circle,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                  'Recent',
                  style: TextStyle(color: AppColors.GreyText),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<List<TransactionDetails>>(
                stream: transactions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  List<TransactionDetails> transactionList =
                      snapshot.data ?? [];
                  transactionList = transactionList.take(20).toList();

                  if (transactionList.isEmpty) {
                    return const Center(child: Text('No transactions yet'));
                  } else {
                    List<TransactionDetails> transactionList =
                        snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: transactionList.length,
                      itemBuilder: (context, index) {
                        TransactionDetails transaction = transactionList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditTransactionPage(
                                    transactionDetails: transaction,
                                  ),
                                ),
                              );
                            },
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
                                        SizedBox(
                                          width: 200,
                                          child: Text(
                                            transaction.description,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          transaction.date,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '${transaction.type == "INCOME" || transaction.type == "REFUND" ? "+" : "-"}${transaction.currency} ${_formatAmount(transaction.amount)}',
                                          style: TextStyle(
                                              color: transaction.type ==
                                                          "INCOME" ||
                                                      transaction.type ==
                                                          "REFUND"
                                                  ? Colors.green
                                                  : Colors.red),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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

String _formatAmount(double amount) {
  NumberFormat formatter = NumberFormat('#,##0.00', 'en_US');
  String formattedAmount = formatter.format(amount);

  // if the amount ends with .00, remove the decimal part
  if (formattedAmount.endsWith('.00')) {
    formattedAmount = formattedAmount.substring(0, formattedAmount.length - 3);
  }

  return formattedAmount;
}

import 'package:budget_alert/components/message_utils.dart';
import 'package:budget_alert/widgets/deletebutton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:budget_alert/models/transaction_model.dart';
import 'widgets/button.dart';
import 'components/app_colors.dart';
import 'widgets/dropdownfield.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class EditTransactionPage extends StatefulWidget {
  final TransactionDetails transactionDetails;

  const EditTransactionPage({Key? key, required this.transactionDetails})
      : super(key: key);

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  List typeOptions = [
    'EXPENSE',
    'INCOME',
    'TRANSFER',
    'ATM Withdrawal',
    'REFUND'
  ];

  Future<void> _selectDateAndTime() async {
    DateTime? _pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (_pickedDate != null) {
      TimeOfDay? _pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (_pickedTime != null) {
        DateTime selectedDateTime = DateTime(
          _pickedDate.year,
          _pickedDate.month,
          _pickedDate.day,
          _pickedTime.hour,
          _pickedTime.minute,
        );

        String formattedDateTime;

        if (isSameDay(selectedDateTime, DateTime.now())) {
          formattedDateTime =
              'Today ${DateFormat('HH:mm').format(selectedDateTime)}';
        } else {
          formattedDateTime =
              DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime);
        }

        setState(() {
          _dateController.text = formattedDateTime;
        });
      }
    }
  }

  late Stream<List<String>> accountOptionsStream;

  String transactionId = '';
  String selectedAccount = 'Cash';
  String selectedType = 'EXPENSE';

  @override
  void initState() {
    super.initState();
    String? userID = FirebaseAuth.instance.currentUser?.uid;

    accountOptionsStream = FirebaseFirestore.instance
        .collection('accounts')
        .where('uid', isEqualTo: userID)
        .orderBy('bankName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                '${doc['bankName']} - ${doc['accountNumber']}' as String)
            .toSet()
            .toList());

    TransactionDetails details = widget.transactionDetails;
    transactionId = widget.transactionDetails.transaction_id;
    _descController.text = widget.transactionDetails.description;
    _dateController.text = widget.transactionDetails.date;
    _amountController.text = widget.transactionDetails.amount.toString();
    selectedAccount = widget.transactionDetails.account;
    selectedType = widget.transactionDetails.type;
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  final _descController = TextEditingController();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  TransactionDetails transactionDetails = TransactionDetails();

  @override
  void dispose() {
    _descController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Transaction'),
        centerTitle: true,
        backgroundColor: AppColors.MainColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          child: StreamBuilder<List<String>>(
            stream: accountOptionsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                List<String> accountOptions = snapshot.data ?? [];

                //remove account num from Cash account
                accountOptions = accountOptions
                    .map(
                        (option) => option.startsWith('Cash') ? 'Cash' : option)
                    .toList();
                print('Account Options: $accountOptions');

                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20.0),
                      CustomDropdownField(
                          labelText: 'Account',
                          value: selectedAccount,
                          options: accountOptions,
                          onChanged: (newAcc) {
                            setState(() {
                              selectedAccount = newAcc;
                            });
                          }),
                      const SizedBox(height: 8.0),
                      CustomDropdownField(
                          labelText: 'Type',
                          value: selectedType,
                          options: typeOptions,
                          onChanged: (newType) {
                            setState(() {
                              selectedType = newType;
                            });
                          }),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          } else {
                            return null;
                          }
                        },
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 16.0, top: 16.0),
                              child: TextField(
                                controller: _dateController,
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  labelText: 'Date & Time',
                                  prefixIcon: Icon(
                                    Icons.calendar_today,
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none),
                                  floatingLabelBehavior:
                                      _dateController.text.isNotEmpty
                                          ? FloatingLabelBehavior.never
                                          : FloatingLabelBehavior.auto,
                                ),
                                readOnly: true,
                                onTap: () {
                                  _selectDateAndTime();
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the amount';
                                  } else {
                                    return null;
                                  }
                                },
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Amount',
                                  floatingLabelBehavior:
                                      _amountController.text.isNotEmpty
                                          ? FloatingLabelBehavior.never
                                          : FloatingLabelBehavior.auto,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30.0),
                      CustomButton(
                        onPress: () async {
                          if (_formKey.currentState!.validate()) {
                            String account = selectedAccount;
                            transactionDetails.account = account;
                            transactionDetails.type = selectedType;
                            transactionDetails.description =
                                _descController.text;
                            transactionDetails.date = _dateController.text;
                            transactionDetails.amount =
                                double.parse(_amountController.text);

                            String formattedDateForFirestore =
                                transactionDetails.date;

                            if (formattedDateForFirestore.startsWith('Today')) {
                              formattedDateForFirestore =
                                  DateFormat('yyyy-MM-dd HH:mm')
                                      .format(DateTime.now());
                            }

                            TransactionDetails updatedTransactionDetails =
                                TransactionDetails(
                              transaction_id: transactionId,
                              account: account,
                              amount: transactionDetails.amount,
                              currency: transactionDetails.currency,
                              date: transactionDetails.date,
                              description: transactionDetails.description,
                              type: transactionDetails.type,
                              uid: userID!,
                            );

                            try {
                              QuerySnapshot<Map<String, dynamic>>
                                  querySnapshot = await FirebaseFirestore
                                      .instance
                                      .collection('transactions')
                                      .where('transaction_id',
                                          isEqualTo: transactionId)
                                      .where('uid',
                                          isEqualTo:
                                              updatedTransactionDetails.uid)
                                      .get();

                              if (querySnapshot.size == 1) {
                                String documentId = querySnapshot.docs[0].id;

                                await FirebaseFirestore.instance
                                    .collection('transactions')
                                    .doc(documentId)
                                    .update(updatedTransactionDetails.toJson());

                                // Navigate back
                                Navigator.pop(context);
                              } else {
                                print(
                                    'Error: Document not found or multiple documents found');
                              }
                            } catch (e) {
                              print(e);
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Failed to update transaction: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      SizedBox(height: 32.0),
                      DeleteButton(
                        onPress: () async {
                          // show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Confirm Deletion"),
                                content: Text(
                                    "Are you sure you want to delete this transaction?"),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        // find the document ID based on tid and uid
                                        QuerySnapshot<Map<String, dynamic>>
                                            querySnapshot =
                                            await FirebaseFirestore.instance
                                                .collection('transactions')
                                                .where('transaction_id',
                                                    isEqualTo: widget
                                                        .transactionDetails
                                                        .transaction_id)
                                                .where('uid',
                                                    isEqualTo: FirebaseAuth
                                                        .instance
                                                        .currentUser!
                                                        .uid)
                                                .get();

                                        if (querySnapshot.size == 1) {
                                          String documentId =
                                              querySnapshot.docs[0].id;

                                          // delete the document using its document ID
                                          await FirebaseFirestore.instance
                                              .collection('transactions')
                                              .doc(documentId)
                                              .delete();

                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        } else {
                                          print(
                                              'Error: Document not found or multiple documents found');
                                        }
                                      } catch (e) {
                                        print('Error deleting transaction: $e');
                                      }
                                    },
                                    child: Text("Delete"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        buttonText: 'Delete Transaction',
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

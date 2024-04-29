import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:budget_alert/models/transaction_model.dart';
import 'widgets/button.dart';
import 'components/app_colors.dart';
import 'widgets/dropdownfield.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  List<String> accountOptions = [
    'Cash',
    'Debit Card',
    'Credit Card',
    'Transfer'
  ];

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

    DateTime currentDate = DateTime.now();
    _dateController.text = 'Today ${DateFormat('HH:mm').format(currentDate)}';
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String selectedAccount = 'Cash';
  String selectedType = 'EXPENSE';
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
        title: Text('Add Transaction'),
        centerTitle: true,
        backgroundColor: AppColors.MainColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
                  .map((option) => option.startsWith('Cash') ? 'Cash' : option)
                  .toList();

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
                    CustomButton(onPress: () async {
                      if (_formKey.currentState!.validate()) {
                        // transactionDetails.account = selectedAccount;
                        String accountNumberString =
                            selectedAccount.split('- ').last;
                        String accountNumber = selectedAccount == 'Cash'
                            ? '0'
                            : accountNumberString;

                        transactionDetails.account = accountNumber;
                        transactionDetails.type = selectedType;
                        transactionDetails.description = _descController.text;
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

                        try {
                          await FirebaseFirestore.instance
                              .collection('transactions')
                              .add({
                            'account': transactionDetails.account,
                            'type': transactionDetails.type,
                            'description': transactionDetails.description,
                            'date': formattedDateForFirestore,
                            'currency': 'LKR',
                            'amount': transactionDetails.amount,
                          });

                          Navigator.pop(context);
                        } catch (e) {
                          print('Error saving transaction: $e');
                        }
                      }
                    }),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

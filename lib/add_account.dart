import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:v1/components/app_colors.dart';
import 'package:v1/models/account_model.dart';
import 'package:v1/widgets/button.dart';
import 'package:v1/widgets/dropdownfield.dart';

class AddAccountPage extends StatefulWidget {
  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  // List bankOptions = [
  //   'Commercial Bank',
  //   'National Savings Bank',
  //   'Bank of Ceylon',
  //   'Sampath Bank'
  // ];

  List bankOptions = [];

  String selectedBank = '';

  final _accController = TextEditingController();
  final _cardController = TextEditingController();
  final _balController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchBankOptions();
  }

  Future<void> fetchBankOptions() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('banks').get();

      List<String> banks =
          querySnapshot.docs.map((doc) => doc.get('name') as String).toList();

      setState(() {
        bankOptions = banks;
        selectedBank = bankOptions.isNotEmpty ? bankOptions[0] : '';
      });
    } catch (e) {
      print('Error fetching bank options: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Account'),
        centerTitle: true,
        backgroundColor: AppColors.MainColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.0),
              CustomDropdownField(
                  labelText: 'Bank',
                  value: selectedBank,
                  options: bankOptions,
                  onChanged: (newBank) {
                    setState(() {
                      selectedBank = newBank;
                    });
                  }),
              SizedBox(height: 16.0),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account number';
                  } else {
                    return null;
                  }
                },
                controller: _accController,
                decoration: InputDecoration(labelText: 'Account Number'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the last 4 digits of the card';
                  } else {
                    return null;
                  }
                },
                controller: _cardController,
                decoration: InputDecoration(labelText: 'Last 4 Digits of Card'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the current balance';
                  } else {
                    return null;
                  }
                },
                controller: _balController,
                decoration: InputDecoration(labelText: 'Current Balance'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 32.0),
              CustomButton(onPress: () async {
                if (_formKey.currentState!.validate()) {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    AccountDetails accountDetails = AccountDetails(
                      bankName: selectedBank,
                      accountNumber: int.parse(_accController.text),
                      lastFourDigits: int.parse(_cardController.text),
                      balance: double.parse(_balController.text),
                      uid: user.uid,
                    );

                    try {
                      await FirebaseFirestore.instance
                          .collection('accounts')
                          .add(accountDetails.toJson());

                      Navigator.pop(context);
                    } catch (e) {
                      print('error saving account: $e');
                    }
                  }
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}

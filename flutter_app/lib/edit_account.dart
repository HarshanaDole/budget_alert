import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_alert/components/app_colors.dart';
import 'package:budget_alert/models/account_model.dart';
import 'package:budget_alert/widgets/button.dart';
import 'package:budget_alert/widgets/dropdownfield.dart';

class EditAccountPage extends StatefulWidget {
  final AccountDetails accountDetails;

  EditAccountPage({required this.accountDetails});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  late String selectedBank;
  final TextEditingController _accController = TextEditingController();
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _balController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    selectedBank = widget.accountDetails.bankName;
    _accController.text = widget.accountDetails.accountNumber;
    _cardController.text = widget.accountDetails.cardNumber;
    _balController.text = widget.accountDetails.balance.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Account'),
        centerTitle: true,
        backgroundColor: AppColors.MainColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.0),
              CustomDropdownField(
                labelText: 'Bank',
                value: selectedBank,
                options: [
                  'Bank A',
                  'Bank B',
                  'Bank C'
                ], // Add your bank options here
                onChanged: (newBank) {
                  setState(() {
                    selectedBank = newBank.toString();
                  });
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _accController,
                decoration: InputDecoration(labelText: 'Account Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _cardController,
                decoration: InputDecoration(labelText: 'Last 4 Digits of Card'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the last 4 digits of the card';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _balController,
                decoration: InputDecoration(labelText: 'Current Balance'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the current balance';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32.0),
              CustomButton(
                onPress: () async {
                  if (_formKey.currentState!.validate()) {
                    AccountDetails updatedAccountDetails = AccountDetails(
                      bankName: selectedBank,
                      accountNumber: _accController.text,
                      cardNumber: _cardController.text,
                      balance: double.parse(_balController.text),
                      uid: FirebaseAuth.instance.currentUser!.uid,
                    );

                    try {
                      await FirebaseFirestore.instance
                          .collection('accounts')
                          .doc(widget.accountDetails.uid)
                          .update(updatedAccountDetails.toJson());
                      Navigator.pop(context);
                    } catch (e) {
                      print('Error updating account: $e');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

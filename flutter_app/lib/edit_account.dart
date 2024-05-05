import 'package:budget_alert/widgets/deletebutton.dart';
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
  List bankOptions = [];
  late String selectedBank;
  final TextEditingController _accController = TextEditingController();
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _balController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchBankOptions();
    selectedBank = widget.accountDetails.bankName;
    _accController.text = widget.accountDetails.accountNumber;
    _cardController.text = widget.accountDetails.cardNumber;
    _balController.text = widget.accountDetails.balance.toString();
  }

  Future<void> fetchBankOptions() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('banks').get();

      List<String> banks =
          querySnapshot.docs.map((doc) => doc.get('name') as String).toList();

      if (widget.accountDetails.bankName != "Cash") {
        banks.remove("Cash");
      }

      banks.sort((a, b) {
        if (a == widget.accountDetails.bankName) return -1;
        if (b == widget.accountDetails.bankName) return 1;
        return a.compareTo(b);
      });

      setState(() {
        bankOptions = banks;
        selectedBank = banks.isNotEmpty ? widget.accountDetails.bankName : '';
      });
    } catch (e) {
      print('Error fetching bank options: $e');
    }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16.0),
                if (selectedBank == "Cash")
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      "Cash",
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                SizedBox(height: 16.0),
                if (selectedBank != "Cash") ...[
                  TextFormField(
                    controller: TextEditingController(
                        text: widget.accountDetails.accountNumber),
                    enabled: false,
                    decoration: InputDecoration(labelText: 'Account Number'),
                  ),
                  CustomDropdownField(
                    labelText: 'Bank',
                    value: selectedBank,
                    options: bankOptions,
                    onChanged: (newBank) {
                      setState(() {
                        selectedBank = newBank.toString();
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: _cardController,
                    decoration:
                        InputDecoration(labelText: 'Last 4 Digits of Card'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the last 4 digits of the card';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                ],
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
                      String account;
                      if (selectedBank == 'Cash') {
                        account = selectedBank;
                      } else {
                        account = '$selectedBank - ${_accController.text}';
                      }
                      String fullAccountNumber = _accController.text;
                      String lastFourDigits = fullAccountNumber.length > 4
                          ? fullAccountNumber
                              .substring(fullAccountNumber.length - 4)
                          : fullAccountNumber;
                      AccountDetails updatedAccountDetails = AccountDetails(
                        account: account,
                        bankName: selectedBank,
                        accountNumber: _accController.text,
                        lastFourDigits: lastFourDigits,
                        cardNumber: _cardController.text,
                        balance: double.parse(_balController.text),
                        uid: FirebaseAuth.instance.currentUser!.uid,
                      );

                      try {
                        // find the document ID based on account number and UID
                        QuerySnapshot<Map<String, dynamic>> querySnapshot =
                            await FirebaseFirestore.instance
                                .collection('accounts')
                                .where('accountNumber',
                                    isEqualTo:
                                        updatedAccountDetails.accountNumber)
                                .where('uid',
                                    isEqualTo: updatedAccountDetails.uid)
                                .get();

                        if (querySnapshot.size == 1) {
                          String documentId = querySnapshot.docs[0].id;

                          // update the document using its document ID
                          await FirebaseFirestore.instance
                              .collection('accounts')
                              .doc(documentId)
                              .update(updatedAccountDetails.toJson());

                          // navigate back
                          Navigator.pop(context);
                        } else {
                          // either no matching document or multiple matching documents
                          print(
                              'Error: Document not found or multiple documents found');
                        }
                      } catch (e) {
                        print('Error updating account: $e');
                      }
                    }
                  },
                ),
                SizedBox(height: 32.0),
                if (selectedBank != "Cash")
                  DeleteButton(
                    onPress: () async {
                      // show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Confirm Deletion"),
                            content: Text(
                                "Deleting an account will also remove all your transactions related to this account. Are you sure you want to delete this account?"),
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
                                    // find the document ID based on account number and UID
                                    QuerySnapshot<Map<String, dynamic>>
                                        querySnapshot = await FirebaseFirestore
                                            .instance
                                            .collection('accounts')
                                            .where('accountNumber',
                                                isEqualTo: widget.accountDetails
                                                    .accountNumber)
                                            .where('uid',
                                                isEqualTo: FirebaseAuth
                                                    .instance.currentUser!.uid)
                                            .get();

                                    if (querySnapshot.size == 1) {
                                      String documentId =
                                          querySnapshot.docs[0].id;

                                      // delete the document using its document ID
                                      await FirebaseFirestore.instance
                                          .collection('accounts')
                                          .doc(documentId)
                                          .delete();

                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    } else {
                                      print(
                                          'Error: Document not found or multiple documents found');
                                    }
                                  } catch (e) {
                                    print('Error deleting account: $e');
                                  }
                                },
                                child: Text("Delete"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    buttonText: 'Delete Account',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

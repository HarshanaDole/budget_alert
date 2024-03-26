import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:v1/components/app_colors.dart';
import 'package:v1/main.dart';
import 'package:v1/registration.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        centerTitle: true,
        backgroundColor: AppColors.MainColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 16.0,
              ),
              if (_errorMessage != null)
                Center(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 32.0),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      bool loginSuccess = await _login(
                        _emailController.text,
                        _passController.text,
                      );
                      if (loginSuccess) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Home(),
                          ),
                        );
                      } else {
                        setState(() {
                          _errorMessage = 'Incorrect email or password';
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    textStyle: TextStyle(fontSize: 18.0),
                  ),
                  child: Text('Login'),
                ),
              ),
              SizedBox(height: 12.0),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RegistrationPage()),
                    );
                  },
                  child: Text(
                    'Register',
                    style: TextStyle(fontSize: 12.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _login(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text, password: _passController.text);

      User? user = userCredential.user;

      if (user != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('accounts')
            .where('uid', isEqualTo: user.uid)
            .where('bankName', isEqualTo: 'Cash')
            .get();

        if (querySnapshot.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('accounts').add({
            'uid': user.uid,
            'bankName': 'Cash',
            'balance': 0,
            'accountNumber': 0,
          });
        }
      }

      return true;
    } catch (e) {
      print('Failed to login: $e');
      return false;
    }
  }
}

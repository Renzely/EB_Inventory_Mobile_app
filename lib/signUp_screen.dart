// ignore_for_file: prefer_const_constructors, prefer_interpolation_to_compose_strings, use_build_context_synchronously, deprecated_member_use, non_constant_identifier_names, no_leading_underscores_for_local_identifiers, unused_local_variable

import 'dart:convert';
import 'package:demo_app/otp_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as M;
import 'package:demo_app/login_screen.dart';
import 'package:demo_app/dbHelper/mongodb.dart';
import 'package:demo_app/dbHelper/mongodbDraft.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  var fnameController = TextEditingController();
  var mnameController = TextEditingController();
  var lnameController = TextEditingController();
  var addressController = TextEditingController();
  var usernameController = TextEditingController();
  var passwordController = TextEditingController();
  var confirmPassController = TextEditingController();
  var contactNumController = TextEditingController();
  var remarksController = TextEditingController();
  var selectedRemarks = 'REGULAR'; // Default choice
  var branchController = TextEditingController(text: 'Branch');
  bool isActivate = false;
  bool isLoading = false;
  int type = 1;

  String? fnameError;
  String? lnameError;
  String? addressError;
  String? contactNumError;
  String? usernameError;
  String? passwordError;
  String? confirmPassError;
  bool obsurePassword = true;
  bool obsureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    List<String> remarksChoices = ['REGULAR', 'RELIVER', 'PROBATIONARY'];
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Center(
              child: Container(
                height: 1200,
                width: 500,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[600]!,
                      Colors.grey[800]!,
                      Colors.grey[900]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'SIGN UP',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    DropdownButtonFormField<String>(
                      value: selectedRemarks,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRemarks = newValue!;
                          remarksController.text = newValue;
                        });
                      },
                      items: remarksChoices
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        hintText: 'Remarks',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      enabled: false, // Disable the TextField
                      controller: branchController,
                      decoration: InputDecoration(
                        hintText: 'Branch',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      obscureText: false,
                      controller: fnameController,
                      decoration: InputDecoration(
                        hintText: 'First Name',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        errorText: fnameError,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      obscureText: false,
                      controller: mnameController,
                      decoration: InputDecoration(
                        hintText: 'Middle Name (Optional)',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Add space between fields
                    TextField(
                      obscureText: false,
                      controller: lnameController,
                      decoration: InputDecoration(
                        hintText: 'Last Name',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        errorText: lnameError,
                      ),
                    ),
                    const SizedBox(height: 20), // Add space between fields
                    TextField(
                      obscureText: false,
                      controller: addressController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        errorText: addressError,
                      ),
                    ),
                    const SizedBox(height: 20), // Add space between fields
                    TextField(
                      obscureText: false,
                      controller: contactNumController,
                      keyboardType:
                          TextInputType.number, // Set keyboard type to number
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly, // Allow only digits
                        LengthLimitingTextInputFormatter(
                            11), // Limit to 11 characters
                      ],
                      decoration: InputDecoration(
                        hintText: 'Contact Number',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        errorText: contactNumError,
                      ),
                      onChanged: (value) {
                        setState(() {
                          // You can add any additional logic here if needed
                        });
                      },
                    ),
                    const SizedBox(height: 20), // Add space between fields
                    TextField(
                      obscureText: false,
                      controller: usernameController,
                      decoration: InputDecoration(
                        hintText: 'Username',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        errorText: usernameError,
                      ),
                    ),
                    const SizedBox(height: 20), // Add space between fields
                    TextField(
                      obscureText: obsurePassword,
                      controller: passwordController,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        errorText: passwordError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obsurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obsurePassword = !obsurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Add space between fields
                    TextField(
                      obscureText: obsureConfirmPassword,
                      controller: confirmPassController,
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        errorText: confirmPassError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obsureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obsureConfirmPassword = !obsureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 35), // Add space between fields
                    ElevatedButton(
                      onPressed: () async {
                        if (_validateFields()) {
                          if (passwordController.text ==
                              confirmPassController.text) {
                            if (await _checkEmailExists(
                                addressController.text)) {
                              setState(() {
                                addressError = "Email Already Exists";
                              });
                            } else {
                              setState(() {
                                isLoading = true; // Set loading to true
                              });

                              await _signUp(
                                fnameController.text,
                                mnameController.text,
                                lnameController.text,
                                addressController.text,
                                usernameController.text,
                                passwordController.text,
                                contactNumController.text,
                                branchController.text,
                                selectedRemarks,
                                isActivate,
                                type,
                              );

                              setState(() {
                                isLoading =
                                    false; // Set loading to false after sign-up completes
                              });
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Passwords do not match")),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(
                              color: Colors.grey,
                            )
                          : Text(
                              'SUBMIT',
                              style: GoogleFonts.roboto(
                                color: Colors.grey,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    const SizedBox(height: 15),
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.roboto(color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginPage(),
                          ),
                        );
                      },
                      child: Text(
                        'SIGN IN',
                        style: GoogleFonts.roboto(
                            color: Colors.blue[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Future<void> _signUp(
    String fName,
    String mName,
    String lName,
    String emailAdd,
    String userN,
    String pass, // Plain text password
    String contact_num,
    String branch,
    String remarks,
    bool isActivate,
    int type,
  ) async {
    final plainPassword = pass; // Store the plain text password for hashing
    final hashedPassword = await hashPassword(plainPassword);

    final userData = {
      'firstName': fName,
      'middleName': mName,
      'lastName': lName,
      'emailAddress': emailAdd, // Updated field name
      'contactNum': contact_num,
      'username': userN,
      'password': hashedPassword,
      'accountNameBranchManning': branch,
      'remarks': remarks,
      'isActivate': isActivate, // Keep as boolean
      'type': type
    };

    // Send OTP after successfully preparing user data
    await _sendOtp(emailAdd, userData);
  }

  Future<void> _sendOtp(String email, Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('http://192.168.50.55:8080/send-otp-register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final receivedOtp = jsonDecode(response.body)['code'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerificationScreen(
            email: email,
            otp: receivedOtp.toString(),
            userData: userData,
          ),
        ),
      );
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP. Please try again.')),
      );
    }
  }

  bool _validateFields() {
    setState(() {
      // First Name validation
      fnameError =
          fnameController.text.isEmpty ? "First Name is required" : null;

      // Last Name validation
      lnameError =
          lnameController.text.isEmpty ? "Last Name is required" : null;

      // Contact Number validation (must be 11 digits)
      if (contactNumController.text.isEmpty) {
        contactNumError = "Contact Number is required";
      } else if (contactNumController.text.length != 11) {
        contactNumError = "Contact Number must be 11 digits";
      } else {
        contactNumError = null;
      }

      // Username validation (minimum 4 characters)
      if (usernameController.text.isEmpty) {
        usernameError = "Username is required";
      } else if (usernameController.text.length < 4) {
        usernameError = "Username must be at least 4 characters";
      } else {
        usernameError = null;
      }

      // Password validation (minimum 6 characters)
      if (passwordController.text.isEmpty) {
        passwordError = "Password is required";
      } else if (passwordController.text.length < 6) {
        passwordError = "Password must be at least 6 characters";
      } else {
        passwordError = null;
      }

      // Confirm Password validation
      confirmPassError = confirmPassController.text.isEmpty
          ? "Confirm Password is required"
          : null;

      // Email validation
      if (addressController.text.isEmpty) {
        addressError = "Email is required";
      } else {
        // Regular expression for email validation
        String pattern = r'^[^@]+@[^@]+\.[^@]+';
        RegExp regex = RegExp(pattern);
        if (!regex.hasMatch(addressController.text)) {
          addressError = "Enter a valid email address";
        } else {
          addressError = null;
        }
      }
    });

    return fnameError == null &&
        lnameError == null &&
        addressError == null &&
        contactNumError == null &&
        usernameError == null &&
        passwordError == null &&
        confirmPassError == null;
  }

  Future<bool> _checkEmailExists(String email) async {
    var user =
        await MongoDatabase.userCollection.findOne({'emailAddress': email});
    return user != null;
  }
}

// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously, unnecessary_null_comparison, use_key_in_widget_constructors, avoid_print, await_only_futures, file_names

import 'dart:convert';

import 'package:demo_app/forgotPass_screen.dart';
import 'package:flutter/material.dart';
import 'package:demo_app/dashboard_screen.dart';
import 'package:demo_app/signUp_screen.dart';
import 'package:demo_app/dbHelper/mongodb.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String usernameErrorText = '';
  String passwordErrorText = '';
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> _login(BuildContext context) async {
    // Start loading
    setState(() {
      _isLoading = true;
    });

    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();

    // Check for empty username and password
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        usernameErrorText = username.isEmpty ? 'Input username' : '';
        passwordErrorText = password.isEmpty ? 'Input password' : '';
        _isLoading = false; // Stop loading if there's an error
      });
      return; // Exit the method if either field is empty
    }

    try {
      final userDetails =
          await MongoDatabase.getUserDetailsByUsername(username);
      if (userDetails != null) {
        final String storedPasswordHash = userDetails['password'];
        final bool isActivated = userDetails['isActivate'];

        // Check if the user is activated
        if (!isActivated) {
          setState(() {
            usernameErrorText = '';
            passwordErrorText = 'Account deactivated. Please contact admin.';
            _isLoading = false; // Stop loading if account is deactivated
          });
          return;
        }

        // Validate the password using the validatePassword function
        if (await validatePassword(password, storedPasswordHash)) {
          // Save login state and user details
          final prefs = await SharedPreferences.getInstance();
          prefs.setBool('isLoggedIn', true);
          prefs.setString('userName', userDetails['firstName'] ?? '');
          prefs.setString('userMiddleName', userDetails['middleName'] ?? '');
          prefs.setString('userLastName', userDetails['lastName'] ?? '');
          prefs.setString('userContactNum', userDetails['contactNum'] ?? '');
          prefs.setString('userEmail', userDetails['emailAddress'] ?? '');

          // Load disabled SKUs before navigating
          // Try to load disabled SKUs
          try {
            await _loadDisabledSkus(userDetails);
          } catch (e) {
            print('Error loading disabled SKUs: $e');
            // Continue navigation without SKUs
          }
          // Navigate to Dashboard
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => SideBarLayout(
                title: "Attendance",
                mainContent: Column(
                  children: <Widget>[
                    DateTimeWidget(),
                    AttendanceWidget(
                      userEmail: userDetails['emailAddress'] ?? '',
                    ),
                  ],
                ),
                userName: userDetails['firstName'] ?? '',
                userLastName: userDetails['lastName'] ?? '',
                userEmail: userDetails['emailAddress'] ?? '',
                userMiddleName: userDetails['middleName'] ?? '',
                userContactNum: userDetails['contactNum'] ?? '',
              ),
            ),
            (Route<dynamic> route) => false,
          );
        } else {
          setState(() {
            passwordErrorText = 'Invalid password';
            _isLoading = false; // Stop loading if the password is invalid
          });
        }
      } else {
        setState(() {
          usernameErrorText = 'Account does not exist';
          _isLoading = false; // Stop loading if the account doesn't exist
        });
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("An error occurred during login. Please try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      setState(() {
        _isLoading = false; // Stop loading if an error occurs
      });
    }
  }

  // New method to load disabled SKUs
  Future<void> _loadDisabledSkus(Map<String, dynamic> userDetails) async {
    String branch = userDetails['branch'] ?? '';
    final prefs = await SharedPreferences.getInstance();

    String key = 'disabledSkus_$branch';

    print("Loading SKUs for branch: $branch");
    print("Using key: $key");

    String? disabledSkusData = prefs.getString(key);

    if (disabledSkusData != null) {
      try {
        Map<String, dynamic> storedData = jsonDecode(disabledSkusData);

        // Check if the expected keys exist
        if (!storedData.containsKey('expiration') ||
            !storedData.containsKey('skus')) {
          print("Corrupted data found. Removing key.");
          prefs.remove(key);
          return;
        }

        DateTime expirationDate = DateTime.parse(storedData['expiration']);

        print("Stored expiration date: $expirationDate");
        print("Today's date: ${DateTime.now()}");

        if (expirationDate.isAfter(DateTime.now())) {
          List<String> skus = List<String>.from(storedData['skus']);

          // Store the loaded SKUs in SharedPreferences
          prefs.setString('loadedSKUs', jsonEncode(skus));
          print("Disabled SKUs loaded: $skus");
        } else {
          prefs.remove(key);
          print("SKUs reset for a new week.");
        }
      } catch (e) {
        print("Error loading disabled SKUs: $e");
        prefs.remove(key);
      }
    } else {
      print("No disabled SKUs found for branch: $branch");
    }
  }

  Future<bool> validatePassword(
      String providedPassword, String storedPasswordHash) async {
    try {
      // Compare the provided password with the hashed password stored in the database
      return await BCrypt.checkpw(providedPassword, storedPasswordHash);
    } catch (e) {
      // Handle error
      print("Error validating password: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(210, 46, 0, 77)!,
              Color.fromARGB(210, 88, 12, 139)!,
              Color.fromARGB(255, 255, 196, 0)!,
            ],
          ),
        ),
        child: SingleChildScrollView(
          // Added SingleChildScrollView
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 80),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "LOGIN",
                        style: GoogleFonts.roboto(
                            color: Colors.white, fontSize: 40),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "WELCOME TO EB INVENTORY",
                        style: GoogleFonts.roboto(
                            color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: MediaQuery.of(context).size.height *
                      0.90, // Adjust height to fit the screen
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      topRight: Radius.circular(60),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: 60),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(210, 46, 0, 77)
                                    .withOpacity(
                                        0.8), // Adjust the opacity if needed
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'USERNAME',
                                    style: GoogleFonts.roboto(
                                      color: Colors.grey[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextFormField(
                                    controller: usernameController,
                                    onChanged: (_) {
                                      setState(() {
                                        usernameErrorText = '';
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Enter your username',
                                      border: InputBorder.none,
                                      prefixIcon: Icon(Icons.account_box),
                                      prefixIconColor:
                                          Color.fromARGB(210, 46, 0, 77),
                                      errorText: usernameErrorText.isNotEmpty
                                          ? usernameErrorText
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PASSWORD',
                                    style: GoogleFonts.roboto(
                                      color: Colors.grey[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextFormField(
                                    controller: passwordController,
                                    onChanged: (_) {
                                      setState(() {
                                        passwordErrorText = '';
                                      });
                                    },
                                    obscureText: _obscureText,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your password',
                                      prefixIcon: Icon(Icons.lock),
                                      prefixIconColor:
                                          Color.fromARGB(210, 46, 0, 77),
                                      border: InputBorder.none,
                                      errorText: passwordErrorText.isNotEmpty
                                          ? passwordErrorText
                                          : null,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureText
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureText = !_obscureText;
                                          });
                                        },
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 40,
                        ),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  _login(context); // Call the login method
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLoading
                                ? Colors.grey
                                : Color.fromARGB(
                                    210, 46, 0, 77), // Grey if loading
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: SizedBox(
                            width: 200,
                            height: 50,
                            child: Center(
                              child: _isLoading
                                  ? CircularProgressIndicator(
                                      color: Colors
                                          .white) // Show spinner if loading
                                  : Text(
                                      'LOGIN',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 40,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to sign-up page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignUp(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Color.fromARGB(210, 46, 0, 77), // Button color
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(50), // Rounded corners
                            ),
                          ),
                          child: SizedBox(
                            width: 50,
                            height: 20,
                            child: Center(
                              child: Text(
                                'SIGN UP',
                                style: GoogleFonts.roboto(
                                  color: Colors.white, // Text color
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to forgot password page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPassword(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Color.fromARGB(210, 46, 0, 77), // Button color
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(50), // Rounded corners
                            ),
                          ),
                          child: SizedBox(
                            width: 130,
                            height: 20,
                            child: Center(
                              child: Text(
                                'FORGOT PASSWORD',
                                style: GoogleFonts.roboto(
                                  color: Colors.white, // Text color
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}

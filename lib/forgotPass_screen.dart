import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:demo_app/changePass_screen.dart';
import 'package:demo_app/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String? receivedOtp;
  bool isOtpSent = false;
  String? otpMessage;
  String? otpErrorMessage;

  bool _isLoading = false;
  bool _isCooldown = false;
  int _cooldownTime = 30; // 30 seconds cooldown
  Timer? _timer;

  void _startCooldown() {
    setState(() {
      _isCooldown = true;
      _cooldownTime = 30; // Set cooldown to 30 seconds
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _cooldownTime--;
        if (_cooldownTime == 0) {
          _isCooldown = false;
          _timer?.cancel();
        }
      });
    });
  }

  void _sendOtp() {
    setState(() {
      _isLoading = true;
    });

    // Simulate sending OTP and waiting for response
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _isLoading = false;
        _startCooldown(); // Start cooldown after sending OTP
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 26, 20, 71),
                  Color.fromARGB(255, 26, 20, 71),
                  Color.fromARGB(255, 255, 196, 0)!,
                ],
              ),
            ),
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
                        "Forgot Password",
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 40,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Recover your account",
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Container(
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // Email Text Field
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email),
                              prefixIconColor: Color.fromARGB(255, 26, 20, 71),
                            ),
                          ),
                          if (otpMessage != null) ...[
                            SizedBox(height: 10),
                            Text(
                              otpMessage!,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                          SizedBox(height: 20),
                          // Send OTP Button
                          ElevatedButton(
                            onPressed: _isLoading || _isCooldown
                                ? null
                                : () {
                                    _sendOtp();
                                    _sendOtpForgotPass(
                                        emailController.text.trim());
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isLoading || _isCooldown
                                  ? Colors.grey
                                  : Color.fromARGB(255, 26, 20,
                                      71), // Grey if loading or cooldown
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
                                    : _isCooldown
                                        ? Text(
                                            'Wait $_cooldownTime s',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18),
                                          ) // Show countdown
                                        : Text(
                                            'SEND OTP',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18),
                                          ),
                              ),
                            ),
                          ),
                          if (isOtpSent) ...[
                            SizedBox(height: 30),
                            // OTP Code Input Field
                            TextFormField(
                              controller: otpController,
                              decoration: InputDecoration(
                                hintText: 'Enter OTP code',
                                prefixIcon: Icon(Icons.lock),
                                prefixIconColor:
                                    Color.fromARGB(255, 26, 20, 71),
                              ),
                            ),
                            if (otpErrorMessage != null) ...[
                              SizedBox(height: 10),
                              Text(
                                otpErrorMessage!,
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                            SizedBox(height: 30),
                            // Verify OTP Button
                            ElevatedButton(
                              onPressed: () {
                                _verifyOtp();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 26, 20, 71),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: SizedBox(
                                width: 200, // Set a fixed width for the button
                                height: 50,
                                child: Center(
                                  child: Text(
                                    "VERIFY OTP",
                                    style: GoogleFonts.roboto(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: 30),
                          // Return to Login Text
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 26, 20,
                                  71), // Match the original text color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    50), // Slightly rounded corners
                              ),
                            ),
                            child: SizedBox(
                              width: 110, // Adjusted width to fit the text
                              height: 30,
                              child: Center(
                                child: Text(
                                  'BACK TO LOGIN',
                                  style: GoogleFonts.roboto(
                                    color: Colors
                                        .white, // Changed to white for better contrast
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13, // Reduced font size slightly
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Future<void> _sendOtpForgotPass(String emailAddress) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.50.55:8080/send-otp-forgotpassword'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'emailAddress': emailAddress,
        }),
      );

      if (response.statusCode == 200) {
        final receivedOtp = jsonDecode(response.body)['code'];
        setState(() {
          this.receivedOtp = receivedOtp;
          isOtpSent = true;
          otpMessage = 'OTP has been sent to your email.';
          otpErrorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP has been sent to your email.')),
        );
      } else if (response.statusCode == 404) {
        setState(() {
          otpMessage = null;
          otpErrorMessage = 'Email does not exist.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email does not exist.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP. Please try again.')),
        );
      }
    } catch (e) {
      print('Error sending OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP. Please try again.')),
      );
    }
  }

  void _verifyOtp() {
    String enteredOtp = otpController.text.trim();
    if (enteredOtp == receivedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verified.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChangePasswordScreen(email: emailController.text.trim()),
        ),
      );
    } else {
      setState(() {
        otpErrorMessage = 'Invalid OTP. Please try again.';
      });
    }
  }
}

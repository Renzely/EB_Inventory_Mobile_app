// ignore_for_file: use_key_in_widget_constructors

import 'package:demo_app/dbHelper/mongodb.dart';
import 'package:demo_app/provider.dart';
import 'package:flutter/material.dart';
import 'package:demo_app/login_screen.dart'; // Import your LoginPage
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo_app/dashboard_screen.dart';
import 'package:google_fonts/google_fonts.dart';

// Import MongoDatabase

void main() async {
  await MongoDatabase.connect();
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final userName = prefs.getString('userName') ?? '';
  final userLastName = prefs.getString('userLastName') ?? '';
  final userEmail = prefs.getString('userEmail') ?? '';
  final userMiddleName = prefs.getString('userMiddleName') ?? '';
  final userContactNum = prefs.getString('userContactNum') ?? '';

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    userName: userName,
    userLastName: userLastName,
    userEmail: userEmail,
    userContactNum: userContactNum,
    userMiddleName: userMiddleName,
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userName;
  final String userLastName;
  final String userEmail;
  final String userMiddleName;
  final String userContactNum;

  const MyApp(
      {required this.isLoggedIn,
      required this.userName,
      required this.userLastName,
      required this.userEmail,
      required this.userContactNum,
      required this.userMiddleName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AttendanceModel(), // Provide AttendanceModel here
      child: MaterialApp(
        theme: ThemeData(
          textTheme: GoogleFonts.robotoTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        home: isLoggedIn
            ? Attendance(
                userName: userName,
                userLastName: userLastName,
                userEmail: userEmail,
                userContactNum: userContactNum,
                userMiddleName: userMiddleName,
              )
            : LoginPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

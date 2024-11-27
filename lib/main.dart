// ignore_for_file: use_key_in_widget_constructors

import 'package:demo_app/dbHelper/mongodb.dart';
import 'package:demo_app/provider.dart';
import 'package:flutter/material.dart';
import 'package:demo_app/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo_app/dashboard_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize connectivity service
  final connectivity = Connectivity();
  connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
    print('Connection status changed ${result.join(', ')}');
    // Handle connection changes here if needed
  });

  await MongoDatabase.connect();
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
  final String userContactNum;
  final String userMiddleName;

  const MyApp({
    required this.isLoggedIn,
    required this.userName,
    required this.userLastName,
    required this.userEmail,
    required this.userContactNum,
    required this.userMiddleName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AttendanceModel(),
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

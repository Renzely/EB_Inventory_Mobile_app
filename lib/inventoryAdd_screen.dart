// ignore_for_file: prefer_final_fields, avoid_print, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, library_private_types_in_public_api, prefer_const_constructors, sort_child_properties_last, prefer_const_literals_to_create_immutables, depend_on_referenced_packages, non_constant_identifier_names, unused_local_variable, use_build_context_synchronously, unused_element, avoid_unnecessary_containers, must_be_immutable

import 'dart:convert';
import 'dart:math';
import 'package:demo_app/dbHelper/constant.dart';
import 'package:demo_app/dbHelper/mongodb.dart';
import 'package:demo_app/dbHelper/mongodbDraft.dart';
import 'package:flutter/services.dart';
import 'package:demo_app/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bson/bson.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shared_preferences/shared_preferences.dart';

class AddInventory extends StatefulWidget {
  final String userName;
  final String userLastName;
  final String userEmail;
  String userContactNum;
  String userMiddleName;

  AddInventory({
    required this.userName,
    required this.userLastName,
    required this.userEmail,
    required this.userContactNum,
    required this.userMiddleName,
  });

  @override
  _AddInventoryState createState() => _AddInventoryState();
}

class _AddInventoryState extends State<AddInventory> {
  late TextEditingController _dateController;
  late DateTime _selectedDate;
  String? _selectedAccount;
  String? _selectedPeriod;
  late GlobalKey<FormState> _formKey;
  bool _isSaveEnabled = false;
  bool _showAdditionalInfo = false;
  TextEditingController _monthController = TextEditingController();
  TextEditingController _weekController = TextEditingController();
  String _selectedWeek = '';
  String _selectedMonth = '';
  List<DropdownMenuItem<String>> _periodItems = [];
  DateTime _currentWeekStart = DateTime.now();

  List<String> _branchList = [];

  @override
  void initState() {
    super.initState();
    _updatePeriodItems();

    _formKey = GlobalKey<FormState>();
    _selectedDate =
        DateTime.now(); // Initialize _selectedDate to the current date
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd')
          .format(_selectedDate), // Set initial text of controller
    );
    _weekController.addListener(() {
      setState(() {
        _selectedWeek = _weekController.text;
      });
    });
    _monthController.addListener(() {
      setState(() {
        _selectedMonth = _monthController.text;
      });
    });
    fetchBranches();
  }

  Future<void> fetchBranches() async {
    try {
      final db = await mongo.Db.create(INVENTORY_CONN_URL);
      await db.open();
      final collection = db.collection(USER_NEW);
      final List<Map<String, dynamic>> branchDocs = await collection
          .find(mongo.where.eq('emailAddress', widget.userEmail))
          .toList();
      setState(() {
        // Extract accountNameBranchManning from branchDocs and handle both single string and list cases
        _branchList = branchDocs
            .map((doc) => doc['accountNameBranchManning'])
            .where((branch) => branch != null)
            .expand((branch) => branch is List ? branch : [branch])
            .map((branch) => branch.toString())
            .toList();
        _selectedAccount = _branchList.isNotEmpty ? _branchList.first : '';
      });
      await db.close();
    } catch (e) {
      print('Error fetching branch data: $e');
    }
  }

  Future<void> fetchBranchForUser(String userEmail) async {
    try {
      final db = await mongo.Db.create(INVENTORY_CONN_URL);
      await db.open();
      final collection = db.collection(USER_NEW);
      final Map<String, dynamic>? userData =
          await collection.findOne(mongo.where.eq('emailAddress', userEmail));
      if (userData != null) {
        final branchData = userData['accountNameBranchManning'];
        setState(() {
          _selectedAccount = branchData is List
              ? branchData.first.toString()
              : branchData.toString();
          _branchList = branchData is List
              ? branchData.map((branch) => branch.toString()).toList()
              : [branchData.toString()];
        });
      }
      await db.close();
    } catch (e) {
      print('Error fetching branch data for user: $e');
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _monthController.dispose();
    _weekController.dispose();
    super.dispose();
  }

  // String generateInputID() {
  //   var timestamp = DateTime.now().millisecondsSinceEpoch;
  //   var random =
  //       Random().nextInt(10000); // Generate a random number between 0 and 9999
  //   var paddedRandom =
  //       random.toString().padLeft(4, '0'); // Ensure it has 4 digits
  //   return '2000$paddedRandom';
  // }
  void _updatePeriodItems() {
    setState(() {
      _periodItems = _getFilteredPeriodItems();
    });
  }

// Method to get filtered period items
  List<DropdownMenuItem<String>> _getFilteredPeriodItems() {
    List<DropdownMenuItem<String>> items = [];

    // Get the current date
    DateTime currentDate = DateTime.now();

    // Find the most recent Monday (start of the period)
    DateTime startOfWeek = currentDate
        .subtract(Duration(days: (currentDate.weekday - DateTime.monday) % 7));

    // Calculate the end of the period (Saturday)
    DateTime endOfWeek = startOfWeek.add(Duration(days: 5));

    // Format the period string
    String periodString =
        '${DateFormat('MMMdd').format(startOfWeek)}-${DateFormat('MMMdd').format(endOfWeek)}';

    items.add(DropdownMenuItem(child: Text(periodString), value: periodString));

    print(
        "Selected period: ${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd').format(endOfWeek)}");

    return items;
  }

// // Method to get the current week start date
//   DateTime getCurrentWeekStartDate({DateTime? overrideDate}) {
//     // Use the overrideDate if provided, otherwise use the actual current date
//     var now = overrideDate ?? DateTime.now();
//     var today = DateTime(now.year, now.month, now.day);
//     var firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));
//     return firstDayOfWeek;
//   }

  List<List<DateTime>> _generatePeriods(DateTime startDate) {
    List<List<DateTime>> periods = [];

    // Generate 5 periods (Monday to Saturday)
    for (int i = 0; i < 5; i++) {
      DateTime periodStart =
          startDate.add(Duration(days: i * 7)); // Start of each week (Monday)
      DateTime periodEnd =
          periodStart.add(Duration(days: 5)); // End of each week (Saturday)
      periods.add([periodStart, periodEnd]);
    }

    return periods;
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        onWillPop: () async => false,
        child: new MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              appBar: AppBar(
                title: Text(
                  'INVENTORY PROCESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                elevation: 0,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 26, 20, 71),
                        Color.fromARGB(255, 33, 26, 87),
                        Color.fromARGB(255, 255, 196, 0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              body: SingleChildScrollView(
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20.0),
                    width: MediaQuery.of(context).size.width * 1.0,
                    child: Form(
                      key: _formKey,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _dateController,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // SizedBox(height: 16),
                            // Text(
                            //   'Input ID',
                            //   style: TextStyle(
                            //       fontWeight: FontWeight.bold, fontSize: 16),
                            // ),
                            // SizedBox(height: 8),
                            // TextFormField(
                            //   initialValue: generateInputID(),
                            //   readOnly: true,
                            //   decoration: InputDecoration(
                            //     border: OutlineInputBorder(),
                            //     contentPadding:
                            //         EdgeInsets.symmetric(horizontal: 12),
                            //     hintText: 'Auto-generated Input ID',
                            //   ),
                            // ),
                            SizedBox(height: 16),
                            Text(
                              'Merchandiser',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              initialValue:
                                  '${widget.userName} ${widget.userLastName}',
                              readOnly: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Branch/Outlet',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.centerRight,
                                      children: [
                                        DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          value: _selectedAccount,
                                          items: _branchList.map((branch) {
                                            return DropdownMenuItem<String>(
                                              value: branch,
                                              child: Text(branch),
                                            );
                                          }).toList(),
                                          onChanged: _branchList.length > 1
                                              ? (value) {
                                                  setState(() {
                                                    _selectedAccount = value;
                                                    _isSaveEnabled =
                                                        _selectedAccount !=
                                                                null &&
                                                            _selectedPeriod !=
                                                                null;
                                                  });
                                                }
                                              : null, // Disable onChange when there is only one branch
                                          decoration: InputDecoration(
                                            hintText: 'Select',
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 12),
                                          ),
                                        ),
                                        // Conditionally show clear button
                                        if (_selectedAccount != null)
                                          Positioned(
                                            right: 8.0,
                                            child: IconButton(
                                              icon: Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedAccount = null;
                                                  _selectedPeriod = null;
                                                  _showAdditionalInfo = false;
                                                  _isSaveEnabled = false;
                                                });
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedAccount != null) ...[
                              SizedBox(height: 16),
                              Text(
                                'Additional Information',
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Weeks Covered',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.black,
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        alignment: Alignment.centerRight,
                                        children: [
                                          DropdownButtonFormField<String>(
                                            value: _selectedPeriod,
                                            items: _periodItems,
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedPeriod = value;
                                                _isSaveEnabled =
                                                    _selectedAccount != null &&
                                                        _selectedPeriod != null;

                                                // Null check before splitting
                                                if (value != null) {
                                                  String actualValue = value
                                                          .split('-')[
                                                      1]; // Get the second part of the date
                                                  print(
                                                      'Selected period: $value');

                                                  switch (value) {
                                                    case 'Mar24-Mar29':
                                                      _monthController.text =
                                                          'March';
                                                      _weekController.text =
                                                          'Week 13';
                                                      break;
                                                    case 'Mar31-Apr05':
                                                      _monthController.text =
                                                          'March';
                                                      _weekController.text =
                                                          'Week 14';
                                                      break;
                                                    case 'Apr07-Apr12':
                                                      _monthController.text =
                                                          'April';
                                                      _weekController.text =
                                                          'Week 15';
                                                      break;
                                                    case 'Apr14-Apr19':
                                                      _monthController.text =
                                                          'April';
                                                      _weekController.text =
                                                          'Week 16';
                                                      break;
                                                    case 'Apr21-Apr26':
                                                      _monthController.text =
                                                          'April';
                                                      _weekController.text =
                                                          'Week 17';
                                                      break;
                                                    case 'Apr28-May03':
                                                      _monthController.text =
                                                          'April';
                                                      _weekController.text =
                                                          'Week 18';
                                                      break;
                                                    case 'May05-May10':
                                                      _monthController.text =
                                                          'May';
                                                      _weekController.text =
                                                          'Week 19';
                                                      break;
                                                    case 'May12-May17':
                                                      _monthController.text =
                                                          'May';
                                                      _weekController.text =
                                                          'Week 20';
                                                      break;
                                                    case 'May19-May24':
                                                      _monthController.text =
                                                          'May';
                                                      _weekController.text =
                                                          'Week 21';
                                                      break;
                                                    case 'May26-May31':
                                                      _monthController.text =
                                                          'May';
                                                      _weekController.text =
                                                          'Week 22';
                                                      break;
                                                    case 'Jun02-Jun07':
                                                      _monthController.text =
                                                          'June';
                                                      _weekController.text =
                                                          'Week 23';
                                                      break;
                                                    case 'Jun09-Jun14':
                                                      _monthController.text =
                                                          'June';
                                                      _weekController.text =
                                                          'Week 24';
                                                      break;
                                                    case 'Jun16-Jun21':
                                                      _monthController.text =
                                                          'June';
                                                      _weekController.text =
                                                          'Week 25';
                                                      break;
                                                    case 'Jun23-Jun28':
                                                      _monthController.text =
                                                          'June';
                                                      _weekController.text =
                                                          'Week 26';
                                                      break;
                                                    case 'Jun30-Jul05':
                                                      _monthController.text =
                                                          'June';
                                                      _weekController.text =
                                                          'Week 27';
                                                      break;
                                                    case 'Jul07-Jul12':
                                                      _monthController.text =
                                                          'July';
                                                      _weekController.text =
                                                          'Week 28';
                                                      break;
                                                    case 'Jul14-Jul19':
                                                      _monthController.text =
                                                          'July';
                                                      _weekController.text =
                                                          'Week 29';
                                                      break;
                                                    case 'Jul21-Jul26':
                                                      _monthController.text =
                                                          'July';
                                                      _weekController.text =
                                                          'Week 30';
                                                      break;
                                                    case 'Jul28-Aug02':
                                                      _monthController.text =
                                                          'July';
                                                      _weekController.text =
                                                          'Week 31';
                                                      break;
                                                    case 'Aug04-Aug09':
                                                      _monthController.text =
                                                          'August';
                                                      _weekController.text =
                                                          'Week 32';
                                                      break;
                                                    case 'Aug11-Aug16':
                                                      _monthController.text =
                                                          'August';
                                                      _weekController.text =
                                                          'Week 33';
                                                      break;
                                                    case 'Aug18-Aug23':
                                                      _monthController.text =
                                                          'August';
                                                      _weekController.text =
                                                          'Week 34';
                                                      break;
                                                    case 'Aug25-Aug30':
                                                      _monthController.text =
                                                          'August';
                                                      _weekController.text =
                                                          'Week 35';
                                                      break;
                                                    case 'Sep01-Sep06':
                                                      _monthController.text =
                                                          'September';
                                                      _weekController.text =
                                                          'Week 36';
                                                      break;
                                                    case 'Sep08-Sep13':
                                                      _monthController.text =
                                                          'September';
                                                      _weekController.text =
                                                          'Week 37';
                                                      break;
                                                    case 'Sep15-Sep20':
                                                      _monthController.text =
                                                          'September';
                                                      _weekController.text =
                                                          'Week 38';
                                                      break;
                                                    case 'Sep22-Sep27':
                                                      _monthController.text =
                                                          'September';
                                                      _weekController.text =
                                                          'Week 39';
                                                      break;
                                                    case 'Sep29-Oct04':
                                                      _monthController.text =
                                                          'September';
                                                      _weekController.text =
                                                          'Week 40';
                                                      break;
                                                    case 'Oct06-Oct11':
                                                      _monthController.text =
                                                          'October';
                                                      _weekController.text =
                                                          'Week 41';
                                                      break;
                                                    case 'Oct13-Oct18':
                                                      _monthController.text =
                                                          'October';
                                                      _weekController.text =
                                                          'Week 42';
                                                      break;
                                                    case 'Oct20-Oct25':
                                                      _monthController.text =
                                                          'October';
                                                      _weekController.text =
                                                          'Week 43';
                                                      break;
                                                    case 'Oct27-Nov01':
                                                      _monthController.text =
                                                          'October';
                                                      _weekController.text =
                                                          'Week 44';
                                                      break;
                                                    case 'Nov03-Nov08':
                                                      _monthController.text =
                                                          'November';
                                                      _weekController.text =
                                                          'Week 45';
                                                      break;
                                                    case 'Nov10-Nov15':
                                                      _monthController.text =
                                                          'November';
                                                      _weekController.text =
                                                          'Week 46';
                                                      break;
                                                    case 'Nov17-Nov22':
                                                      _monthController.text =
                                                          'November';
                                                      _weekController.text =
                                                          'Week 47';
                                                      break;
                                                    case 'Nov24-Nov29':
                                                      _monthController.text =
                                                          'November';
                                                      _weekController.text =
                                                          'Week 48';
                                                      break;
                                                    case 'Dec01-Dec06':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 49';
                                                      break;
                                                    case 'Dec08-Dec13':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 50';
                                                      break;
                                                    case 'Dec15-Dec20':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 51';
                                                      break;
                                                    case 'Dec22-Dec27':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 52';
                                                      break;
                                                    case 'Dec29-Jan03':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 1';
                                                      break;
                                                    case 'Jan05-Jan10':
                                                      _monthController.text =
                                                          'January';
                                                      _weekController.text =
                                                          'Week 2';
                                                      break;

                                                    default:
                                                      _monthController.clear();
                                                      _weekController.clear();
                                                      break;
                                                  }
                                                } else {
                                                  // Handle null value case
                                                  _monthController.clear();
                                                  _weekController.clear();
                                                }
                                                _showAdditionalInfo = true;
                                              });
                                            },
                                            decoration: InputDecoration(
                                              hintText: 'Select Period',
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 12),
                                            ),
                                          ),
                                          if (_selectedPeriod != null)
                                            Positioned(
                                              right: 8.0,
                                              child: IconButton(
                                                icon: Icon(Icons.clear),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedPeriod = null;
                                                    _showAdditionalInfo = false;
                                                    _isSaveEnabled = false;
                                                  });
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_showAdditionalInfo) ...[
                                SizedBox(height: 16),
                                Text('Month',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    )),
                                SizedBox(height: 8),
                                TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'Select Period',
                                    border: OutlineInputBorder(),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  controller: _monthController,
                                  readOnly: true,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Week',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'Select Period',
                                    border: OutlineInputBorder(),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  controller: _weekController,
                                  readOnly: true,
                                ),
                              ],
                            ],
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    // Perform cancel action

                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => Inventory(
                                          userName: widget.userName,
                                          userLastName: widget.userLastName,
                                          userEmail: widget.userEmail,
                                          userContactNum: widget.userContactNum,
                                          userMiddleName: widget.userMiddleName,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ButtonStyle(
                                      padding: MaterialStateProperty.all<
                                          EdgeInsetsGeometry>(
                                        const EdgeInsets.symmetric(
                                            vertical: 15),
                                      ),
                                      minimumSize:
                                          MaterialStateProperty.all<Size>(
                                        const Size(150, 50),
                                      ),
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Color.fromARGB(255, 26, 20, 71))),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _isSaveEnabled
                                      ? () {
                                          Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      SKUInventory(
                                                        userName:
                                                            widget.userName,
                                                        userLastName:
                                                            widget.userLastName,
                                                        userEmail:
                                                            widget.userEmail,
                                                        userContactNum: widget
                                                            .userContactNum,
                                                        userMiddleName: widget
                                                            .userMiddleName,
                                                        selectedAccount:
                                                            _selectedAccount ??
                                                                '',
                                                        SelectedPeriod:
                                                            _selectedPeriod!,
                                                        selectedWeek:
                                                            _selectedWeek,
                                                        selectedMonth:
                                                            _selectedMonth,
                                                        // inputid: generateInputID(),
                                                      )));
                                        }
                                      : null,
                                  style: ButtonStyle(
                                    padding: MaterialStateProperty.all<
                                        EdgeInsetsGeometry>(
                                      const EdgeInsets.symmetric(vertical: 15),
                                    ),
                                    minimumSize:
                                        MaterialStateProperty.all<Size>(
                                      const Size(150, 50),
                                    ),
                                    backgroundColor: _isSaveEnabled
                                        ? MaterialStateProperty.all<Color>(
                                            Color.fromARGB(255, 26, 20, 71))
                                        : MaterialStateProperty.all<Color>(
                                            Colors.grey),
                                  ),
                                  child: const Text(
                                    'Next',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ]),
                    ),
                  ),
                ),
              ),
            )));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }
}

class SKUInventory extends StatefulWidget {
  final String userName;
  final String userLastName;
  final String userEmail;
  final String selectedAccount;
  final String SelectedPeriod;
  final String selectedWeek;
  final String selectedMonth;
  //final String inputid;
  String userContactNum;
  String userMiddleName;

  SKUInventory({
    required this.userName,
    required this.userLastName,
    required this.userEmail,
    required this.selectedAccount,
    required this.SelectedPeriod,
    required this.selectedWeek,
    required this.selectedMonth,
    // required this.inputid,
    required this.userContactNum,
    required this.userMiddleName,
  });

  @override
  _SKUInventoryState createState() => _SKUInventoryState();
}

class _SKUInventoryState extends State<SKUInventory> {
  bool _isDropdownVisible = false;
  String? _selectedaccountname;
  String? _selectedDropdownValue;
  String? _productDetails;
  String? _skuCode;
  String? _versionSelected;
  String? _statusSelected;
  String? _selectedPeriod;
  String? _remarksOOS;
  String? _reasonOOS;
  String? _selectedNoDeliveryOption;
  String? _previousSelectedSku;
  String _inputid = '';
  int? _selectedNumberOfDaysOOS;
  bool _showCarriedTextField = false;
  bool _showNotCarriedTextField = false;
  bool _showDelistedTextField = false;
  bool _isSaveEnabled = false;
  bool _isEditing = true;
  Set<String> _selectedSkus = {}; // Stores all selected SKUs
  List<String> _delistedSkus = [];
  List<String> _disabledSkus = [];
  List<Map<String, dynamic>> _inventorySections = [];
  TextEditingController _beginningSAController = TextEditingController();
  TextEditingController _beginningWAController = TextEditingController();
  TextEditingController _endingSAController = TextEditingController();
  TextEditingController _endingWAController = TextEditingController();
  TextEditingController _beginningController = TextEditingController();
  TextEditingController _deliveryController = TextEditingController();
  TextEditingController _endingController = TextEditingController();
  TextEditingController _offtakeController = TextEditingController();
  TextEditingController _inventoryDaysLevelController = TextEditingController();
  TextEditingController _accountNameController = TextEditingController();
  TextEditingController _productsController = TextEditingController();
  TextEditingController _skuCodeController = TextEditingController();
  TextEditingController _noPOController = TextEditingController();
  TextEditingController _unservedController = TextEditingController();
  TextEditingController _nodeliveryController = TextEditingController();
  List<Widget> _expiryFields = [];
  List<Map<String, dynamic>> _expiryFieldsValues = [];
  bool _showNoPOTextField = false;
  bool _showUnservedTextField = false;
  bool _showNoDeliveryDropdown = false;
  String selectedBranch = 'BranchName'; // Get this from user input or selection
  List<String> _availableSkuDescriptions = [];
  bool _disabledDropdown = false;

  String generateInputID() {
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    var random =
        Random().nextInt(10000); // Generate a random number between 0 and 9999
    var paddedRandom =
        random.toString().padLeft(4, '0'); // Ensure it has 4 digits
    return '2000$paddedRandom';
  }

  Future<void> _updateEditingStatus(
      String inputId, String userEmail, bool isEditing) async {
    try {
      final db = await mongo.Db.create(
          INVENTORY_CONN_URL); // Ensure 'mongo' is imported correctly
      await db.open();
      final collection = db.collection(USER_INVENTORY);

      // Update the document where 'inputId' and 'userEmail' match, setting 'isEditing' to the provided value
      await collection.update(
        mongo.where.eq('inputId', inputId).eq('userEmail', userEmail),
        mongo.modify.set('isEditing', isEditing),
      );

      await db.close();
    } catch (e) {
      print('Error updating editing status: $e');
    }
  }

  void _saveInventoryItem() async {
    try {
      String inputid = _inputid;
      String AccountManning = _selectedaccountname ?? '';
      String period = _selectedPeriod ?? '';
      String Version = _versionSelected ?? '';
      String status = _statusSelected ?? '';
      String SKUDescription = _selectedDropdownValue ?? '';
      String product = _productDetails ?? '';
      String skucode = _skuCode ?? '';
      String remarksOOS = _remarksOOS ?? '';
      String reasonOOS = _reasonOOS ?? '';
      bool edit = _isEditing;
      int numberOfDaysOOS = _selectedNumberOfDaysOOS ?? 0;

      int beginningSA = int.tryParse(_beginningSAController.text) ?? 0;
      int beginningWA = int.tryParse(_beginningWAController.text) ?? 0;
      int newBeginning = beginningSA + beginningWA;

      int endingSA = int.tryParse(_endingSAController.text) ?? 0;
      int endingWA = int.tryParse(_endingWAController.text) ?? 0;
      int newEnding = endingSA + endingWA;

      int beginning = int.tryParse(_beginningController.text) ?? 0;
      int delivery = int.tryParse(_deliveryController.text) ?? 0;
      int ending = int.tryParse(_endingController.text) ?? 0;
      int offtake = beginning + delivery - ending;

      double inventoryDaysLevel = 0;
      if (status != "Not Carried" && status != "Delisted") {
        if (offtake != 0 && ending != double.infinity && !ending.isNaN) {
          inventoryDaysLevel = ending / (offtake / 7);
        }
      }

      dynamic ncValue = 'NC';
      dynamic delistedValue = 'Delisted';
      dynamic beginningValue = beginning;
      dynamic beginningSAValue = beginningSA;
      dynamic beginningWAValue = beginningWA;
      dynamic deliveryValue = delivery;
      dynamic endingValue = ending;
      dynamic endingSAValue = endingSA;
      dynamic endingWAValue = endingWA;
      dynamic offtakeValue = offtake;
      dynamic noOfDaysOOSValue = numberOfDaysOOS;

      if (status == 'Delisted') {
        beginningValue = delistedValue;
        beginningSAValue = deliveryValue;
        beginningWAValue = delistedValue;
        deliveryValue = delistedValue;
        endingValue = delistedValue;
        endingSAValue = delistedValue;
        endingWAValue = deliveryValue;
        offtakeValue = delistedValue;
        noOfDaysOOSValue = delistedValue;
        _expiryFieldsValues = [
          {'expiryMonth': delistedValue, 'expiryPcs': delistedValue}
        ];
      } else if (status == 'Not Carried') {
        beginningValue = ncValue;
        beginningSAValue = ncValue;
        beginningWAValue = ncValue;
        deliveryValue = ncValue;
        endingValue = ncValue;
        endingSAValue = ncValue;
        endingWAValue = ncValue;
        offtakeValue = ncValue;
        noOfDaysOOSValue = ncValue;
        _expiryFieldsValues = [
          {'expiryMonth': ncValue, 'expiryPcs': ncValue}
        ];
      }

      // Create Inventory (Original)
      InventoryItem newItem1 = InventoryItem(
        id: ObjectId(),
        userEmail: widget.userEmail ?? '',
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        inputId: inputid ?? '',
        name: '${widget.userName ?? ''} ${widget.userLastName ?? ''}',
        accountNameBranchManning: widget.selectedAccount ?? '',
        period: widget.SelectedPeriod ?? '',
        month: widget.selectedMonth ?? '',
        week: widget.selectedWeek ?? '',
        // category: Version ?? '',
        skuDescription: SKUDescription ?? '',
        skuCode: skucode ?? '',
        status: status ?? '',
        beginning: beginningValue ?? 0,
        beginningSA: beginningSAValue ?? 0,
        beginningWA: beginningWAValue ?? 0,
        delivery: deliveryValue ?? 0,
        ending: endingValue ?? 0,
        endingSA: endingSAValue ?? 0,
        endingWA: endingWAValue ?? 0,
        offtake: offtakeValue ?? 0,
        inventoryDaysLevel: inventoryDaysLevel?.toDouble() ?? 0.0,
        noOfDaysOOS: noOfDaysOOSValue ?? 0,
        expiryFields: _expiryFieldsValues ?? [],
        remarksOOS: remarksOOS ?? '',
        // reasonOOS: reasonOOS ?? '',
        isEditing: true,
      );

      // Save the original inventory item
      await _saveToDatabase(newItem1);

      // Create multiple additional inventory items from _inventorySections
      // Create multiple additional inventory items from _inventorySections
      for (var section in _inventorySections) {
        String newInputId =
            generateInputID(); // Generate a unique inputId for each item

        // Extract status
        String sectionStatus = section['statusSelected'] ?? '';

        // Default numeric values
        dynamic ncValue = 'NC';
        dynamic delistedValue = 'Delisted';
        dynamic beginningValue =
            int.tryParse(section['beginningController']?.text ?? '0') ?? 0;
        dynamic beginningSAValue =
            int.tryParse(section['beginningSAController']?.text ?? '0') ?? 0;
        dynamic beginningWAValue =
            int.tryParse(section['beginningWAController']?.text ?? '0') ?? 0;
        dynamic deliveryValue =
            int.tryParse(section['deliveryController']?.text ?? '0') ?? 0;
        dynamic endingValue =
            int.tryParse(section['endingController']?.text ?? '0') ?? 0;
        dynamic endingSAValue =
            int.tryParse(section['endingSAController']?.text ?? '0') ?? 0;
        dynamic endingWAValue =
            int.tryParse(section['endingWAController']?.text ?? '0') ?? 0;
        dynamic offtakeValue =
            int.tryParse(section['offtakeController']?.text ?? '0') ?? 0;
        dynamic noOfDaysOOSValue = section['selectedNumberOfDaysOOS'] ?? 0;

        // Check status and apply appropriate values
        if (sectionStatus == 'Delisted') {
          beginningValue = delistedValue;
          beginningSAValue = deliveryValue;
          beginningWAValue = delistedValue;
          deliveryValue = delistedValue;
          endingValue = delistedValue;
          endingSAValue = delistedValue;
          endingWAValue = deliveryValue;
          offtakeValue = delistedValue;
          noOfDaysOOSValue = delistedValue;
          _expiryFieldsValues = [
            {'expiryMonth': delistedValue, 'expiryPcs': delistedValue}
          ];
        } else if (sectionStatus == 'Not Carried') {
          beginningValue = ncValue;
          beginningSAValue = ncValue;
          beginningWAValue = ncValue;
          deliveryValue = ncValue;
          endingValue = ncValue;
          endingSAValue = ncValue;
          endingWAValue = ncValue;
          offtakeValue = ncValue;
          noOfDaysOOSValue = ncValue;
          _expiryFieldsValues = [
            {'expiryMonth': ncValue, 'expiryPcs': ncValue}
          ];
        }

        // Create new inventory item with updated values
        InventoryItem newItem = InventoryItem(
          id: ObjectId(),
          userEmail: widget.userEmail ?? '',
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          inputId: newInputId, // Use the newly generated inputId
          name: '${widget.userName ?? ''} ${widget.userLastName ?? ''}',
          accountNameBranchManning: widget.selectedAccount ?? '',
          period: widget.SelectedPeriod ?? '',
          month: widget.selectedMonth ?? '',
          week: widget.selectedWeek ?? '',
          // category: section['versionSelected'] ?? '',
          skuDescription: section['skuDescription'] ?? '',
          skuCode: section['skuCode'] ?? '',
          status: sectionStatus,
          beginning: beginningValue,
          beginningSA: beginningSAValue,
          beginningWA: beginningWAValue,
          delivery: deliveryValue,
          ending: endingValue,
          endingSA: endingSAValue,
          endingWA: endingWAValue,
          offtake: offtakeValue,
          inventoryDaysLevel: double.tryParse(
                  section['inventoryDaysLevelController']?.text ?? '0.0') ??
              0.0,
          noOfDaysOOS: noOfDaysOOSValue,
          expiryFields: _expiryFieldsValues ?? [],
          remarksOOS: section['remarksOOS'] ?? '',
          // reasonOOS: section['reasonOOS'] ?? '',
          isEditing: true,
        );

        // Save each additional inventory item
        await _saveToDatabase(newItem);
      }

      // If SKU is delisted, remove it from dropdown
      if (status == 'Delisted') {
        setState(() {
          _categoryToSkuDescriptions[_versionSelected]?.remove(SKUDescription);
        });
      }

      // // Refresh dropdown after saving
      // updateDropdown();

      // Update editing status
      if (_isEditing) {
        await _updateEditingStatus(inputid, widget.userEmail, true);
      }
    } catch (e) {
      print('Error saving inventory items: $e');
    }
  }

  Future<void> _saveToDatabase(InventoryItem item) async {
    try {
      final db = await mongo.Db.create(INVENTORY_CONN_URL);
      await db.open();
      final collection = db.collection(USER_INVENTORY);
      final Map<String, dynamic> itemMap = item.toJson();
      await collection.insert(itemMap);
      await db.close();
      print('Inventory item saved to database');
    } catch (e) {
      print('Error saving inventory item: $e');
    }
  }

  Future<List<InventoryItem>> getUserInventoryItems(
      String userEmail, String selectedAccountName) async {
    List<InventoryItem> items = [];
    try {
      final db = await mongo.Db.create(INVENTORY_CONN_URL);
      await db.open();
      final collection = db.collection(USER_INVENTORY);

      // Fetch items where the SKU is not delisted and belongs to the selected account
      final result = await collection.find({
        'userEmail': userEmail,
        'accountNameBranchManning': selectedAccountName,
        'status': {'\$ne': 'Delisted'}, // Exclude delisted items
      }).toList();

      for (var doc in result) {
        items.add(InventoryItem.fromJson(doc));
      }

      await db.close();
    } catch (e) {
      print('Error fetching inventory items: $e');
    }
    return items;
  }

  void _addExpiryField(int sectionIndex) {
    setState(() {
      List expiryFields;
      List expiryFieldsValues;

      if (sectionIndex == -1) {
        // Use original inventory fields
        expiryFields = _expiryFields;
        expiryFieldsValues = _expiryFieldsValues;
      } else {
        // Ensure the section exists and initialize fields if they are null
        if (_inventorySections[sectionIndex]['expiryFields'] == null) {
          _inventorySections[sectionIndex]['expiryFields'] = [];
        }
        if (_inventorySections[sectionIndex]['expiryFieldsValues'] == null) {
          _inventorySections[sectionIndex]['expiryFieldsValues'] = [];
        }
        expiryFields = _inventorySections[sectionIndex]['expiryFields'];
        expiryFieldsValues =
            _inventorySections[sectionIndex]['expiryFieldsValues'];
      }

      if (expiryFields.length < 6) {
        int index = expiryFields.length;
        expiryFieldsValues.add({'expiryMonth': '', 'expiryPcs': 0});

        expiryFields.add(
          ExpiryField(
            index: index,
            onExpiryFieldChanged: (month, pcs, index) {
              _updateExpiryField(sectionIndex, index,
                  {'expiryMonth': month, 'expiryPcs': pcs});
            },
            onDeletePressed: () {
              _removeExpiryField(sectionIndex, index);
            },
          ),
        );
      }
    });
  }

  void _removeExpiryField(int sectionIndex, int index) {
    setState(() {
      // Use the sectionIndex to determine which inventory section to update
      var expiryFields = sectionIndex == -1
          ? _expiryFields
          : _inventorySections[sectionIndex]['expiryFields'];
      var expiryFieldsValues = sectionIndex == -1
          ? _expiryFieldsValues
          : _inventorySections[sectionIndex]['expiryFieldsValues'];

      expiryFields.removeAt(index);
      expiryFieldsValues.removeAt(index);

      // Update the index of remaining fields
      for (int i = index; i < expiryFields.length; i++) {
        expiryFields[i] = ExpiryField(
          index: i,
          onExpiryFieldChanged: (month, pcs, index) {
            _updateExpiryField(
                sectionIndex, index, {'expiryMonth': month, 'expiryPcs': pcs});
          },
          onDeletePressed: () {
            _removeExpiryField(sectionIndex, i);
          },
        );
      }
    });
  }

  void _updateExpiryField(
      int sectionIndex, int index, Map<String, dynamic> newValue) {
    setState(() {
      // Use the sectionIndex to determine which inventory section to update
      var expiryFieldsValues = sectionIndex == -1
          ? _expiryFieldsValues
          : _inventorySections[sectionIndex]['expiryFieldsValues'];

      if (index < expiryFieldsValues.length) {
        expiryFieldsValues[index] = newValue;
      } else {
        // Ensure list has enough entries before updating
        while (expiryFieldsValues.length <= index) {
          expiryFieldsValues.add({'expiryMonth': '', 'expiryPcs': 0});
        }
        expiryFieldsValues[index] = newValue;
      }
    });

    // print("Expiry Values: $expiryFieldsValues"); // Debugging
  }

  Map<String, List<String>> _categoryToSkuDescriptions = {
    'Variant': [
      "Engkanto Live it Up Lager",
      "Engkanto High Hive Honey Ale",
      "Engkanto Paint Me Purple - Ube Lager",
      "Engkanto Mango Nation Hazy IPA",
      "Engkanto Green Lava Double IPA",
      "Engkanto Nutty & Nice Choco Nut Stout",
      "S&R Sun Daze Golden Ale"
    ],
  };

  Map<String, Map<String, String>> _skuToProductSkuCode = {
    'Engkanto Live it Up Lager': {
      'Product': ' ',
      '4-Pack Barcode': '4 806534 610144'
    },
    'Engkanto High Hive Honey Ale': {
      'Product': ' ',
      '4-Pack Barcode': '4 806534 610168'
    },
    'Engkanto Paint Me Purple - Ube Lager': {
      'Product': ' ',
      '4-Pack Barcode': '4 806534 610410'
    },
    'Engkanto Mango Nation Hazy IPA': {
      'Product': ' ',
      '4-Pack Barcode': '4 806534 610175'
    },
    'Engkanto Green Lava Double IPA': {
      'Product': ' ',
      '4-Pack Barcode': '4 806534 610151'
    },
    'Engkanto Nutty & Nice Choco Nut Stout': {
      'Product': ' ',
      '4-Pack Barcode': '4 806534 610502'
    },
    'S&R Sun Daze Golden Ale': {
      'Product': ' ',
      '4-Pack Barcode': '4 806534 610403'
    },
  };

  void _toggleDropdown(String version) {
    setState(() {
      if (_versionSelected == version) {
        // If the selected version is clicked again, clear and reset
        _versionSelected = null; // Clear version selection
        _isDropdownVisible = false; // Hide dropdown

        // Reset the fields as needed
        _remarksOOS = null;
        _selectedNoDeliveryOption = null;
        _reasonOOS = null;
        _showNoDeliveryDropdown = false;
        _selectedNumberOfDaysOOS = 0;
        _selectedDropdownValue = null; // Clear dropdown selection
        _productDetails = null;
        _skuCode = null;
        _expiryFields.clear();
        _statusSelected = null;
        _showCarriedTextField = false;
        _showNotCarriedTextField = false;
        _showDelistedTextField = false;

        // Clear text field controllers
        _beginningController.clear();
        _beginningSAController.clear();
        _beginningWAController.clear();
        _deliveryController.clear();
        _endingSAController.clear();
        _endingWAController.clear();
        _endingController.clear();
        _offtakeController.clear();

        // Reset the disabled SKU list (to enable SKUs again)
        _disabledSkus.clear();
      } else {
        // If a different version is clicked, select the version and show dropdown
        _versionSelected = version;
        _isDropdownVisible = true; // Show dropdown for the selected version
        _selectedDropdownValue =
            null; // Reset dropdown selection when switching versions

        // If we're switching versions, make sure we load the correct SKU descriptions
        // Update disabledSkus list if necessary for the new version
      }
    });
  }

  void _selectSKU(String? newValue) {
    if (newValue != null && _skuToProductSkuCode.containsKey(newValue)) {
      // Store previous selection to potentially re-enable it
      String? previousSelection = _selectedDropdownValue;

      setState(() {
        _selectedDropdownValue = newValue;
        _productDetails = _skuToProductSkuCode[newValue]!['Product'];
        _skuCode = _skuToProductSkuCode[newValue]!['4-Pack Barcode'];

        // Add to disabled SKUs to prevent selection in other dropdowns
        if (!_disabledSkus.contains(newValue)) {
          _disabledSkus.add(newValue);
        }

        // Re-enable previous selection if it's different
        if (previousSelection != null && previousSelection != newValue) {
          _disabledSkus.remove(previousSelection);
        }

        _updateSelectedSkus(); // Update selected SKUs immediately
      });

      // Save the disabled state
      _saveSelectedSku(newValue);
    }
  }

  void _selectSKUnewinventory(String? newValue, int index) {
    if (newValue != null && _skuToProductSkuCode.containsKey(newValue)) {
      // Store previous selection to potentially re-enable it
      String? previousSelection = _inventorySections[index]['skuDescription'];

      setState(() {
        _inventorySections[index]['skuDescription'] = newValue;
        _inventorySections[index]['productDetails'] =
            _skuToProductSkuCode[newValue]!['Product'];
        _inventorySections[index]['skuCode'] =
            _skuToProductSkuCode[newValue]!['4-Pack Barcode'];

        // Add to disabled SKUs to prevent selection in other dropdowns
        if (!_disabledSkus.contains(newValue)) {
          _disabledSkus.add(newValue);
        }

        // Re-enable previous selection if it's different
        if (previousSelection != null && previousSelection != newValue) {
          _disabledSkus.remove(previousSelection);
        }

        _updateSelectedSkus(); // Ensure UI updates to reflect disabled options
      });

      // Save the disabled state
      _saveSelectedSku(newValue);
    }
  }

  void _updateSelectedSkus() {
    Set<String> newSelectedSkus = {}; // Use a set to avoid duplicates

    if (_selectedDropdownValue != null) {
      newSelectedSkus.add(_selectedDropdownValue!); // Original SKU
    }

    for (var section in _inventorySections) {
      if (section['skuDescription'] != null) {
        newSelectedSkus.add(section['skuDescription']); // Additional SKU
      }
    }

    setState(() {
      _selectedSkus =
          newSelectedSkus; // Update only after processing all selections

      // Make sure all selected SKUs are in the disabled list to prevent duplicate selection
      _disabledSkus = List<String>.from(_selectedSkus);
    });

    print("Updated Selected SKUs: $_selectedSkus");
    print("Updated Disabled SKUs: $_disabledSkus");
  }

  void _addNewInventorySection() {
    setState(() {
      _inventorySections.add({
        'skuDescription': null,
        'productDetails': null,
        'skuCode': null,
        'versionSelected': null,
        'statusSelected':
            null, // ✅ Add status selection (Carried, Not Carried, Delisted)
        'productsController':
            TextEditingController(), // ✅ Add controller for product details
        'skuCodeController':
            TextEditingController(), // ✅ Add controller for SKU Code
      });
      _updateSelectedSkus(); // ✅ Update selected SKUs immediately
    });
  }

  void _confirmSave() {
    if (_selectedDropdownValue != null) {
      _saveSelectedSku(_selectedDropdownValue!);
      // Optionally, show a confirmation dialog or message here
    }
  }

  void _toggleCarriedTextField(String status, [int? index]) {
    setState(() {
      if (index != null) {
        // Updating additional inventory section separately
        _inventorySections[index]['statusSelected'] = status;
        _inventorySections[index]['showCarriedTextField'] = true;
        _inventorySections[index]['showNotCarriedTextField'] = false;
        _inventorySections[index]['showDelistedTextField'] = false;
      } else {
        // Updating the original inventory
        _statusSelected = status;
        _showCarriedTextField = true;
        _showNotCarriedTextField = false;
        _showDelistedTextField = false;
      }
    });
  }

  void _toggleNotCarriedTextField(String status, [int? index]) {
    setState(() {
      if (index != null) {
        _inventorySections[index]['statusSelected'] = status;
        _inventorySections[index]['showCarriedTextField'] = false;
        _inventorySections[index]['showNotCarriedTextField'] = true;
        _inventorySections[index]['showDelistedTextField'] = false;
      } else {
        _statusSelected = status;
        _showCarriedTextField = false;
        _showNotCarriedTextField = true;
        _showDelistedTextField = false;

        // ✅ Reset OOS Fields
        _selectedNumberOfDaysOOS = null;
        _remarksOOS = null;
        _reasonOOS = null;
        _showNoDeliveryDropdown = false;
      }
    });
  }

  void _toggleDelistedTextField(String status, [int? index]) {
    setState(() {
      if (index != null) {
        _inventorySections[index]['statusSelected'] = status;
        _inventorySections[index]['showCarriedTextField'] = false;
        _inventorySections[index]['showNotCarriedTextField'] = false;
        _inventorySections[index]['showDelistedTextField'] = true;
      } else {
        _statusSelected = status;
        _showCarriedTextField = false;
        _showNotCarriedTextField = false;
        _showDelistedTextField = true;

        // ✅ Reset OOS Fields
        _selectedNumberOfDaysOOS = null;
        _remarksOOS = null;
        _reasonOOS = null;
        _showNoDeliveryDropdown = false;
      }
    });
  }

  DateTime _getStartOfWeek() {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;

    // Move back to the Monday of the current week
    now = now.subtract(Duration(days: currentWeekday - DateTime.monday));

    return DateTime(
        now.year, now.month, now.day, 0, 0, 0); // Monday at 12:00 AM
  }

// Get end of the week (Saturday)
  DateTime _getEndOfWeek() {
    DateTime startOfWeek = _getStartOfWeek();
    return startOfWeek.add(Duration(days: 5)); // Saturday at 12:00 AM
  }

  Future<void> _saveSelectedSku(String selectedSku,
      {bool isDelisted = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String branch = widget.selectedAccount;
      String key = 'disabledSkus_$branch';

      // Load current SKUs
      String? disabledSkusData = prefs.getString(key);
      Map<String, dynamic> storedData =
          disabledSkusData != null ? jsonDecode(disabledSkusData) : {};
      List<String> currentDisabledSkus =
          List<String>.from(storedData['skus'] ?? []);
      List<String> currentDelistedSkus =
          List<String>.from(storedData['Delisted'] ?? []);

      // Re-enable previous SKU if different from current selection
      if (_previousSelectedSku != null && _previousSelectedSku != selectedSku) {
        currentDisabledSkus.remove(_previousSelectedSku);
        print("SKU $_previousSelectedSku re-enabled.");
      }

      // Update SKU lists
      if (isDelisted) {
        if (!currentDelistedSkus.contains(selectedSku)) {
          currentDelistedSkus.add(selectedSku);
          print("SKU $selectedSku marked as Delisted.");
        }
      } else {
        if (!currentDisabledSkus.contains(selectedSku) &&
            !currentDelistedSkus.contains(selectedSku)) {
          currentDisabledSkus.add(selectedSku);
          print("SKU $selectedSku added to Disabled list.");
        }
      }

      // Collect all selected SKUs from inventory
      Set<String> allSelectedSkus = {};
      if (_selectedDropdownValue != null) {
        allSelectedSkus.add(_selectedDropdownValue!);
      }
      for (var section in _inventorySections) {
        if (section['skuDescription'] != null) {
          allSelectedSkus.add(section['skuDescription']);
        }
      }

      // Merge selected SKUs with disabled list
      currentDisabledSkus =
          List<String>.from({...currentDisabledSkus, ...allSelectedSkus});

      // Update expiration only on Sunday
      DateTime now = DateTime.now();
      if (now.weekday == DateTime.sunday) {
        storedData['expiration'] = _getStartOfWeek().toIso8601String();
      }

      // Prepare data to store
      Map<String, dynamic> dataToStore = {
        'expiration':
            storedData['expiration'] ?? _getStartOfWeek().toIso8601String(),
        'skus': currentDisabledSkus,
        'Delisted': currentDelistedSkus,
      };

      // Save to SharedPreferences
      await prefs.setString(key, jsonEncode(dataToStore));

      // Update state
      setState(() {
        _disabledSkus = currentDisabledSkus;
        _delistedSkus = currentDelistedSkus;
      });

      print("Updated Disabled SKUs: $_disabledSkus");

      // Save previous SKU for next selection
      _previousSelectedSku = selectedSku;

      // Save selected SKUs separately
      await _saveSelectedSkusState(allSelectedSkus);
    } catch (e) {
      print("Error saving SKU: $e");
    }
  }

  Future<void> _saveSelectedSkusState(Set<String> skus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedSkus', jsonEncode(skus.toList()));
      print("Selected SKUs saved: $skus");
    } catch (e) {
      print("Error saving selected SKUs: $e");
    }
  }

  Future<void> _loadDisabledSkus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String branch = widget.selectedAccount;
      String key = 'disabledSkus_$branch';

      String? disabledSkusData = prefs.getString(key);
      List<String> allSkus = _categoryToSkuDescriptions[_versionSelected] ?? [];
      List<String> savedDisabledSkus = [];
      _delistedSkus = []; // Reset before loading

      if (disabledSkusData == null) {
        print("No disabled SKUs found for branch: $branch");
        _disabledSkus = [];
        return;
      }

      Map<String, dynamic> storedData = jsonDecode(disabledSkusData);
      DateTime now = DateTime.now();
      DateTime expirationDate = DateTime.parse(storedData['expiration']);
      savedDisabledSkus = List<String>.from(storedData['skus'] ?? []);
      _delistedSkus = List<String>.from(storedData['Delisted'] ?? []);

      print("Loaded Data from SharedPreferences: $storedData");

      // Ensure expiration is not reset prematurely
      if (now.weekday == DateTime.sunday) {
        print("Sunday reset: Clearing disabled SKUs (keeping delisted).");
        savedDisabledSkus.clear(); // Reset disabled SKUs, keep delisted SKUs

        // Save the reset data
        Map<String, dynamic> updatedData = {
          'expiration': _getStartOfWeek().toIso8601String(),
          'skus': savedDisabledSkus,
          'Delisted': _delistedSkus,
        };
        await prefs.setString(key, jsonEncode(updatedData));
        print("Disabled SKUs reset and saved.");
      } else if (now.isAfter(expirationDate)) {
        print("Expiration passed, updating for the next week.");
        storedData['expiration'] = _getStartOfWeek().toIso8601String();
        await prefs.setString(key, jsonEncode(storedData));
      }

      // Load SKUs for Monday-Saturday
      if (now.weekday >= DateTime.monday && now.weekday <= DateTime.saturday) {
        _disabledSkus = [...savedDisabledSkus, ..._delistedSkus];
      }

      setState(() {
        print("Disabled SKUs loaded: $_disabledSkus");
        print("Delisted SKUs loaded: $_delistedSkus");
      });
    } catch (e) {
      print("Error loading disabled SKUs: $e");
      _disabledSkus = [];
      _delistedSkus = [];
    }
  }

  bool _checkIfDelisted(String selectedSku) {
    // Example logic to check if the SKU should be delisted
    if (selectedSku.contains("Delisted")) {
      // Replace with your actual condition
      return true;
    }
    return false;
  }

  // Future<void> updateDropdown() async {
  //   List<InventoryItem> inventoryItems =
  //       await getUserInventoryItems(widget.userEmail, widget.selectedAccount);

  //   // Initialize a map to group SKUs by category
  //   Map<String, List<String>> categoryToSkuDescriptions = {};

  //   for (var item in inventoryItems) {
  //     // Check if the category exists, and then add the SKU description to that category
  //     if (categoryToSkuDescriptions.containsKey(item.category)) {
  //       categoryToSkuDescriptions[item.category]!.add(item.skuDescription);
  //     } else {
  //       categoryToSkuDescriptions[item.category] = [item.skuDescription];
  //     }
  //   }

  //   setState(() {
  //     _categoryToSkuDescriptions =
  //         categoryToSkuDescriptions; // Update the dropdown items
  //   });
  // }

  void _updateDropdownState() {
    // Get the current weekday (1 = Monday, ..., 7 = Sunday)
    final int today = DateTime.now().weekday;

    // Enable dropdown only from Friday to Sunday
    setState(() {
      _disabledDropdown = !(today == 5 || today == 6 || today == 7);
    });
  }

  @override
  void initState() {
    super.initState();
    _inputid = generateInputID();
    _updateDropdownState();

    // Load disabled SKUs after the frame is built
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _loadDisabledSkus();
    });

    // Add listeners with lambda functions to pass index
    for (int i = 0; i < _inventorySections.length; i++) {
      _inventorySections[i]['beginningController'].addListener(() {
        _calculateOfftake(i);
      });

      _inventorySections[i]['deliveryController'].addListener(() {
        _calculateOfftake(i);
      });

      _inventorySections[i]['endingController'].addListener(() {
        _calculateOfftake(i);
      });

      _inventorySections[i]['offtakeController'].addListener(() {
        _calculateInventoryDaysLevel(i);
      });
    }

    // // Keep other listeners intact
    // _beginningController.addListener(_calculateBeginning);
    _beginningController.addListener(_calculateOfftake);
    _deliveryController.addListener(_calculateOfftake);
    _endingController.addListener(_calculateOfftake);
    _offtakeController.addListener(_calculateInventoryDaysLevel);
    checkSaveEnabled();

    // Add this method call at the end of initState
    _setupAccountChangeListener();
  }

// New method to handle account changes
  void _setupAccountChangeListener() {
    // Assuming widget.selectedAccount is a String property
    String currentAccount = widget.selectedAccount;

    // Create a ValueNotifier to track account changes
    final accountNotifier = ValueNotifier<String>(currentAccount);

    // Listen for changes in the selected account
    accountNotifier.addListener(() {
      setState(() {
        _loadDisabledSkus();
      });
    });

    // Update the accountNotifier when widget.selectedAccount changes
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (currentAccount != widget.selectedAccount) {
        currentAccount = widget.selectedAccount;
        accountNotifier.value = currentAccount;
      }
    });
  }

  @override
  void dispose() {
    _beginningController.dispose();
    _deliveryController.dispose();
    _endingController.dispose();
    _offtakeController.dispose();
    _inventoryDaysLevelController.dispose();
    _noPOController.dispose();
    _unservedController.dispose();
    _nodeliveryController.dispose();
    super.dispose();
  }

  void _calculateBeginning([int? index]) {
    if (index == null) {
      int beginningSA = int.tryParse(_beginningSAController.text) ?? 0;
      int beginningWA = int.tryParse(_beginningWAController.text) ?? 0;
      int totalBeginning = beginningSA + beginningWA;
      _beginningController.text = totalBeginning.toString();
    } else {
      int beginningSA = int.tryParse(
              _inventorySections[index]['beginningSAController'].text) ??
          0;
      int beginningWA = int.tryParse(
              _inventorySections[index]['beginningWAController'].text) ??
          0;
      int totalBeginning = beginningSA + beginningWA;
      _inventorySections[index]['beginningController'].text =
          totalBeginning.toString();
    }
  }

  void _calculateEnding([int? index]) {
    if (index == null) {
      int endingSA = int.tryParse(_endingSAController.text) ?? 0;
      int endingWA = int.tryParse(_endingWAController.text) ?? 0;
      int totalEnding = endingSA + endingWA;
      _endingController.text = totalEnding.toString();
    } else {
      int endingSA =
          int.tryParse(_inventorySections[index]['endingSAController'].text) ??
              0;
      int endingWA =
          int.tryParse(_inventorySections[index]['endingWAController'].text) ??
              0;
      int totalEnding = endingSA + endingWA;
      _inventorySections[index]['endingController'].text =
          totalEnding.toString();
    }
  }

  void _calculateOfftake([int? index]) {
    if (index == null) {
      double beginning = double.tryParse(_beginningController.text) ?? 0;
      double delivery = double.tryParse(_deliveryController.text) ?? 0;
      double ending = double.tryParse(_endingController.text) ?? 0;
      double offtake = beginning + delivery - ending;
      _offtakeController.text = offtake.toStringAsFixed(2);
    } else {
      double beginning = double.tryParse(
              _inventorySections[index]['beginningController'].text) ??
          0;
      double delivery = double.tryParse(
              _inventorySections[index]['deliveryController'].text) ??
          0;
      double ending =
          double.tryParse(_inventorySections[index]['endingController'].text) ??
              0;
      double offtake = beginning + delivery - ending;
      _inventorySections[index]['offtakeController'].text =
          offtake.toStringAsFixed(2);
    }

    _calculateInventoryDaysLevel(index);
  }

  void _calculateInventoryDaysLevel([int? index]) {
    if (index == null) {
      double ending = double.tryParse(_endingController.text) ?? 0;
      double offtake = double.tryParse(_offtakeController.text) ?? 0;
      double inventoryDaysLevel = (offtake == 0) ? 0 : ending / (offtake / 7);
      _inventoryDaysLevelController.text =
          inventoryDaysLevel == 0 ? '' : inventoryDaysLevel.toStringAsFixed(2);
    } else {
      double ending =
          double.tryParse(_inventorySections[index]['endingController'].text) ??
              0;
      double offtake = double.tryParse(
              _inventorySections[index]['offtakeController'].text) ??
          0;
      double inventoryDaysLevel = (offtake == 0) ? 0 : ending / (offtake / 7);
      _inventorySections[index]['inventoryDaysLevelController'].text =
          inventoryDaysLevel == 0 ? '' : inventoryDaysLevel.toStringAsFixed(2);
    }
  }

  bool _isInventoryComplete(int index) {
    final section = _inventorySections[index];

    // If status is Not Carried or Delisted, no need to check fields
    if (section['statusSelected'] == 'Not Carried' ||
        section['statusSelected'] == 'Delisted') {
      return true;
    }

    // If status is Carried, check if all required fields are filled
    if (section['statusSelected'] == 'Carried') {
      // Check required fields
      bool areRequiredFieldsFilled =
          section['beginningSAController'].text.trim().isNotEmpty &&
              section['beginningWAController'].text.trim().isNotEmpty &&
              section['endingSAController'].text.trim().isNotEmpty &&
              section['endingWAController'].text.trim().isNotEmpty &&
              section['deliveryController'].text.trim().isNotEmpty;

      // Check No. of Days OOS and related fields
      bool areOOSFieldsValid = true;
      if (section['selectedNumberOfDaysOOS'] == null) {
        areOOSFieldsValid = false; // Ensure a selection is required
      } else if (section['selectedNumberOfDaysOOS']! > 0) {
        areOOSFieldsValid = section['remarksOOS'] != null &&
            (section['remarksOOS'] != 'No Delivery' ||
                section['selectedNoDeliveryOption'] != null);
      }

      return areRequiredFieldsFilled && areOOSFieldsValid;
    }

    // Default to false if status is not set
    return false;
  }

  void checkSaveEnabled() {
    bool allInventoriesComplete = true;

    // If status is 'Carried', check if original inventory is complete
    if (_statusSelected == 'Carried' && !_isOriginalInventoryComplete()) {
      allInventoriesComplete = false;
    }

    // If status is NOT 'Delisted', check OOS fields
    if (_statusSelected != 'Delisted' && _statusSelected != 'Not Carried') {
      // Ensure No. of Days OOS is selected
      if (_selectedNumberOfDaysOOS == null) {
        allInventoriesComplete = false;
      }

      // Ensure Remarks is selected when OOS Days is greater than 0
      void checkSaveEnabled() {
        bool allInventoriesComplete = true;

        // If status is 'Carried', check if original inventory is complete
        if (_statusSelected == 'Carried' && !_isOriginalInventoryComplete()) {
          allInventoriesComplete = false;
        }

        // If status is NOT 'Delisted', check OOS fields
        if (_statusSelected != 'Delisted' && _statusSelected != 'Not Carried') {
          // Ensure No. of Days OOS is selected
          if (_selectedNumberOfDaysOOS == null) {
            allInventoriesComplete = false;
          }

          // Ensure Remarks is selected when OOS Days is greater than 0
          if (_selectedNumberOfDaysOOS != null &&
              _selectedNumberOfDaysOOS! > 0) {
            if (_remarksOOS == null) {
              allInventoriesComplete = false;
            }

            // Ensure Reason is selected if "No Delivery" is chosen in Remarks
            if (_remarksOOS == 'No Delivery' && _reasonOOS == null) {
              allInventoriesComplete = false;
            }
          }
        }

        // Check each additional inventory section
        for (int i = 0; i < _inventorySections.length; i++) {
          if (!_isInventoryComplete(i)) {
            allInventoriesComplete = false;
            break;
          }
        }

        // Enable the save button only if all conditions are met
        setState(() {
          _isSaveEnabled = allInventoriesComplete;
        });
      }
    }

    // Check each additional inventory section
    for (int i = 0; i < _inventorySections.length; i++) {
      if (!_isInventoryComplete(i)) {
        allInventoriesComplete = false;
        break;
      }
    }

    // Enable the save button only if all conditions are met
    setState(() {
      _isSaveEnabled = allInventoriesComplete;
    });
  }

// New function to check if the original inventory is complete
  bool _isOriginalInventoryComplete() {
    return _beginningController.text.isNotEmpty &&
        _deliveryController.text.isNotEmpty &&
        _endingController.text.isNotEmpty &&
        _offtakeController.text.isNotEmpty;
  }

  void RemarkSaveEnable() {
    setState(() {
      // Enable the Save button only if a reason is selected when No Delivery dropdown is shown
      if (_showNoDeliveryDropdown) {
        _isSaveEnabled = _selectedNoDeliveryOption != null;
      } else {
        _isSaveEnabled = true; // or other conditions based on your app logic
      }
    });
  }

  bool isSaveEnabled = false;

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        onWillPop: () async => false,
        child: new MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              appBar: AppBar(
                  title: Text(
                    'INVENTORY PROCESS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  elevation: 0,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 26, 20, 71),
                          Color.fromARGB(255, 33, 26, 87),
                          Color.fromARGB(255, 255, 196, 0),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddInventory(
                                  userName: widget.userName,
                                  userLastName: widget.userLastName,
                                  userEmail: widget.userEmail,
                                  userContactNum: widget.userContactNum,
                                  userMiddleName: widget.userMiddleName,
                                )),
                      );
                    },
                  )),
              body: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  // Wrap with SingleChildScrollView
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 10),
                      Text(
                        'Input ID',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        initialValue: generateInputID(),
                        readOnly: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          hintText: 'Auto-generated Input ID',
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Week Number',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextField(
                        controller: _accountNameController,
                        readOnly: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          hintText: widget.selectedWeek,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Month',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextField(
                        controller: _accountNameController,
                        readOnly: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          hintText: widget.selectedMonth,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Branch/Outlet',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextField(
                        controller: _accountNameController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: widget.selectedAccount,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Category',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _toggleDropdown('Variant'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  width: 2.0,
                                  color: _versionSelected == 'Variant'
                                      ? Color.fromARGB(255, 26, 20, 71)
                                      : Colors.blueGrey.shade200,
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text('Variant',
                                  style: TextStyle(color: Colors.black)),
                            ),
                          ),
                        ],
                      ),

// Add space between version buttons and dropdown
                      SizedBox(height: 20),

// SKU Description dropdown
                      if (_isDropdownVisible && _versionSelected != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                'SKU Description',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              hint: Text('Select SKU Description'),
                              value: _selectedDropdownValue, // This can be null
                              onChanged: (String? newValue) {
                                if (newValue != null &&
                                    !_disabledSkus.contains(newValue) &&
                                    !_delistedSkus.contains(newValue)) {
                                  setState(() {
                                    _selectedDropdownValue = newValue;
                                  });
                                  _selectSKU(newValue);
                                }
                              },
                              items: (_categoryToSkuDescriptions[
                                          _versionSelected] ??
                                      [])
                                  .map<DropdownMenuItem<String>>(
                                (String value) {
                                  bool isMainSelection =
                                      value == _selectedDropdownValue;

                                  bool isSelectedInInventory =
                                      _inventorySections.any((section) =>
                                          section['skuDescription'] == value);

                                  bool isDisabled =
                                      _disabledSkus.contains(value) ||
                                          _delistedSkus.contains(value) ||
                                          isSelectedInInventory;

                                  String displayText = value;
                                  Color textColor = Colors.black;

                                  if (isMainSelection) {
                                    displayText = "$value (SELECTED)";
                                    textColor = Color.fromARGB(255, 26, 20, 71);
                                  } else if (isSelectedInInventory) {
                                    int inventoryIndex = _inventorySections
                                        .indexWhere((section) =>
                                            section['skuDescription'] == value);
                                    displayText =
                                        "$value (IN INVENTORY ${inventoryIndex + 2})";
                                    textColor = Colors.blue;
                                  } else if (isDisabled) {
                                    displayText = "$value (DISABLED)";
                                    textColor = Colors.red;
                                  }

                                  return DropdownMenuItem<String>(
                                    value: value,
                                    enabled: !isDisabled,
                                    child: Container(
                                      width: double
                                          .infinity, // Ensures full width is available
                                      child: Text(
                                        displayText,
                                        style: TextStyle(color: textColor),
                                        overflow: TextOverflow
                                            .ellipsis, // Apply ellipsis if text overflows
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                              isExpanded:
                                  true, // Ensure dropdown takes up full width
                              decoration: InputDecoration(
                                labelText: 'Select SKU Description',
                                border: OutlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_productDetails != null)
                            SizedBox(
                              width: 115, // Same fixed width
                              child: OutlinedButton(
                                onPressed: () {
                                  _toggleCarriedTextField('Carried');
                                  checkSaveEnabled(); // Call checkSaveEnabled when category changes
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    width: 2.0,
                                    color: _statusSelected == 'Carried'
                                        ? Color.fromARGB(255, 26, 20, 71)
                                        : Colors.blueGrey.shade200,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  'Carried',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          if (_productDetails != null)
                            SizedBox(
                              width: 130, // Same fixed width
                              child: OutlinedButton(
                                onPressed: () {
                                  _toggleNotCarriedTextField('Not Carried');
                                  checkSaveEnabled(); // Call checkSaveEnabled when category changes
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    width: 2.0,
                                    color: _statusSelected == 'Not Carried'
                                        ? Color.fromARGB(255, 26, 20, 71)
                                        : Colors.blueGrey.shade200,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  'Not Carried',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          if (_productDetails != null)
                            SizedBox(
                              width: 115, // Same fixed width
                              child: OutlinedButton(
                                onPressed: () {
                                  _toggleDelistedTextField('Delisted');
                                  checkSaveEnabled(); // Call checkSaveEnabled when category changes
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    width: 2.0,
                                    color: _statusSelected == 'Delisted'
                                        ? Color.fromARGB(255, 26, 20, 71)
                                        : Colors.blueGrey.shade200,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  'Delisted',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 15),
                      // Conditionally showing the 'Beginning' field with its label
                      if (_showCarriedTextField) ...[
                        Text(
                          'Beginning PCS (Selling Area)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _beginningSAController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onChanged: (_) {
                            _calculateBeginning(); // Calculate on change
                            checkSaveEnabled();
                          },
                        ),
                        SizedBox(height: 10),
                      ],
                      SizedBox(height: 15),
                      // Conditionally showing the 'BeginningWA' field with its label
                      if (_showCarriedTextField) ...[
                        Text(
                          'Beginning PCS (Warehouse Area)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _beginningWAController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onChanged: (_) {
                            _calculateBeginning(); // Calculate on change
                            checkSaveEnabled();
                          },
                        ),
                        SizedBox(height: 10),
                      ],
                      SizedBox(height: 15),
                      if (_showCarriedTextField) ...[
                        Text(
                          'Ending PCS (Selling Area)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _endingSAController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onChanged: (_) {
                            _calculateEnding(); // Calculate on change
                            checkSaveEnabled();
                          },
                        ),
                        SizedBox(height: 10),
                      ],
                      SizedBox(height: 15),
                      // Conditionally showing the 'BeginningWA' field with its label
                      if (_showCarriedTextField) ...[
                        Text(
                          'Ending PCS (Warehouse Area)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _endingWAController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onChanged: (_) {
                            _calculateEnding(); // Calculate on change
                            checkSaveEnabled();
                          },
                        ),
                        SizedBox(height: 10),
                      ],
                      SizedBox(height: 15),
                      // Conditionally showing the 'Beginning' field with its label
                      if (_showCarriedTextField) ...[
                        Text(
                          'Beginning',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          readOnly: true,
                          controller: _beginningController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onChanged: (_) => checkSaveEnabled(),
                        ),
                        SizedBox(height: 10),
                      ],

// Conditionally showing the 'Delivery' field with its label
                      if (_showCarriedTextField) ...[
                        Text(
                          'Delivery PCS',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _deliveryController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onChanged: (_) => checkSaveEnabled(),
                        ),
                        SizedBox(height: 10),
                      ],
// Conditionally showing the 'Ending' field with its label
                      if (_showCarriedTextField) ...[
                        Text(
                          'Ending',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          readOnly: true,
                          controller: _endingController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onChanged: (_) => checkSaveEnabled(),
                        ),
                        SizedBox(height: 10),
                      ],
                      SizedBox(height: 20),
                      if (_showCarriedTextField) ...[
                        Center(
                          child: SizedBox(
                            width: 450, // Set the width of the button
                            child: OutlinedButton(
                              onPressed: () => _addExpiryField(
                                  -1), // Pass -1 for original inventory
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    width: 2.0,
                                    color: Color.fromARGB(255, 26, 20, 71)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Text(
                                'Add Expiry',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        if (_expiryFields.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              for (int i = 0; i < _expiryFields.length; i++)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(child: _expiryFields[i]),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        _removeExpiryField(-1,
                                            i); // Pass -1 for original inventory
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                      ],

                      SizedBox(height: 16),
                      if (_showCarriedTextField) ...[
                        Text(
                          'Offtake',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _offtakeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
// Conditionally showing the 'Inventory Days Level' field with its label
                      if (_showCarriedTextField) ...[
                        Text(
                          'Inventory Days Level',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _inventoryDaysLevelController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],

                      SizedBox(height: 10),
// Conditionally display 'No. of Days OOS' and the DropdownButtonFormField
                      if (_showCarriedTextField) ...[
                        Text(
                          'No. of Days OOS',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          value: _selectedNumberOfDaysOOS,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedNumberOfDaysOOS = newValue;

                              // Reset the remarks and reason when OOS changes
                              _remarksOOS = null;
                              _selectedNoDeliveryOption = null;
                              //_reasonOOS = null;

                              // Hide the No Delivery dropdown if OOS Days is 0
                              if (_selectedNumberOfDaysOOS == 0) {
                                _showNoDeliveryDropdown = false;
                              }

                              // Check if Save button should be enabled
                              checkSaveEnabled();
                            });
                          },
                          items: List.generate(8, (index) {
                            return DropdownMenuItem<int>(
                              value: index,
                              child: Text(index.toString()),
                            );
                          }),
                        ),
                        SizedBox(height: 10),
                      ],
                      SizedBox(height: 10),
                      if (_selectedNumberOfDaysOOS != null &&
                          _selectedNumberOfDaysOOS! > 0) ...[
                        Text(
                          'REMARKS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            labelText:
                                'Enter Remarks', // You can customize the label if needed
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _remarksOOS = value;

                              // Show or hide the Select Reason dropdown based on the Remarks input
                              if (_remarksOOS == 'No Delivery' &&
                                  _selectedNumberOfDaysOOS! > 0) {
                                _showNoDeliveryDropdown = true;
                              } else {
                                _showNoDeliveryDropdown = false;
                                _selectedNoDeliveryOption = null;
                              }

                              // Check if Save button should be enabled
                              checkSaveEnabled();
                            });
                          },
                        ),
                        SizedBox(height: 30),
                      ],
                      Column(
                        children: [
                          for (int i = 0; i < _inventorySections.length; i++)
                            if (_inventorySections[i] != null)
                              Column(
                                children: [
                                  _buildInventorySection(i),
                                  SizedBox(height: 20),
                                ],
                              ),
                        ],
                      ),
                      if (_showCarriedTextField ||
                          _showNotCarriedTextField ||
                          _showDelistedTextField)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _isSaveEnabled
                                  ? () {
                                      setState(() {
                                        int newIndex =
                                            _inventorySections.length;

                                        _inventorySections.add({
                                          'versionSelected': '',
                                          'skuDescription': '',
                                          'productDetails': '',
                                          'skuCode': '',
                                          'beginningSAController':
                                              TextEditingController(),
                                          'beginningWAController':
                                              TextEditingController(),
                                          'endingSAController':
                                              TextEditingController(),
                                          'endingWAController':
                                              TextEditingController(),
                                          'beginningController':
                                              TextEditingController(),
                                          'endingController':
                                              TextEditingController(),
                                          'deliveryController':
                                              TextEditingController(),
                                          'offtakeController':
                                              TextEditingController(),
                                          'inventoryDaysLevelController':
                                              TextEditingController(),
                                          'selectedNumberOfDaysOOS': 0,
                                          'remarksOOS': '',
                                          'selectedNoDeliveryOption': '',
                                          'reasonOOS': '',
                                          'showNoDeliveryDropdown': false,
                                          'expiryFields': [],
                                        });

                                        // Attach listeners for auto-updating calculations
                                        _inventorySections[newIndex]
                                                ['beginningController']
                                            .addListener(() {
                                          _calculateOfftake(newIndex);
                                        });

                                        _inventorySections[newIndex]
                                                ['deliveryController']
                                            .addListener(() {
                                          _calculateOfftake(newIndex);
                                        });

                                        _inventorySections[newIndex]
                                                ['endingController']
                                            .addListener(() {
                                          _calculateOfftake(newIndex);
                                        });

                                        _inventorySections[newIndex]
                                                ['offtakeController']
                                            .addListener(() {
                                          _calculateInventoryDaysLevel(
                                              newIndex);
                                        });

                                        checkSaveEnabled(); // Ensure buttons enable/disable dynamically
                                      });
                                    }
                                  : null, // Disabled until the first inventory form is completed
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all<
                                    EdgeInsetsGeometry>(
                                  const EdgeInsets.symmetric(vertical: 15),
                                ),
                                minimumSize: MaterialStateProperty.all<Size>(
                                  const Size(150, 50),
                                ),
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        _isSaveEnabled
                                            ? Color.fromARGB(255, 255, 196, 0)
                                            : Colors.grey),
                              ),
                              child: const Text(
                                'Add Inventory',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 26, 20, 71),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 20), // Space between buttons

                            ElevatedButton(
                              onPressed: _isSaveEnabled
                                  ? () async {
                                      bool confirmed = await showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Save Confirmation'),
                                            content: Text(
                                                'Are you sure you want to save this inventory?'),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(false); // Cancel
                                                },
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(true); // Confirm
                                                },
                                                child: Text('Confirm'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirmed ?? false) {
                                        _saveInventoryItem();

                                        if (_selectedDropdownValue != null) {
                                          bool isDelisted =
                                              (_statusSelected == "Delisted");
                                          if (isDelisted) {
                                            _delistedSkus
                                                .add(_selectedDropdownValue!);
                                          } else {
                                            _disabledSkus
                                                .add(_selectedDropdownValue!);
                                          }
                                          _saveSelectedSku(
                                              _selectedDropdownValue!,
                                              isDelisted: isDelisted);
                                        }

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Inventory item saved'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );

                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => AddInventory(
                                              userName: widget.userName,
                                              userLastName: widget.userLastName,
                                              userEmail: widget.userEmail,
                                              userContactNum:
                                                  widget.userContactNum,
                                              userMiddleName:
                                                  widget.userMiddleName,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all<
                                    EdgeInsetsGeometry>(
                                  const EdgeInsets.symmetric(vertical: 15),
                                ),
                                minimumSize: MaterialStateProperty.all<Size>(
                                  const Size(150, 50),
                                ),
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        _isSaveEnabled
                                            ? Color.fromARGB(255, 26, 20, 71)
                                            : Colors.grey),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            )));
  }

  Widget _buildInventorySection(int index) {
    final section = _inventorySections[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Divider(thickness: 8, color: Color.fromARGB(255, 26, 20, 71)),
        Center(
          child: Text(
            'INVENTORY  #${index + 2}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
        ),

        SizedBox(height: 15),
        Text(
          'Input ID',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        TextFormField(
          initialValue: generateInputID(),
          readOnly: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
            hintText: 'Auto-generated Input ID',
          ),
        ),
        SizedBox(height: 15),

        // Version Selection Buttons (V1, V2, V3)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Category V1 Button
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    String previousVersion =
                        _inventorySections[index]['versionSelected'];
                    String? previousSku =
                        _inventorySections[index]['skuDescription'];

                    // If changing the version, reset dependent fields
                    if (previousVersion != 'Variant') {
                      _inventorySections[index]['skuDescription'] = null;
                      _inventorySections[index]['productDetails'] = "";
                      _inventorySections[index]['skuCode'] = "";

                      _inventorySections[index]['beginningSAController']
                          .clear();
                      _inventorySections[index]['beginningWAController']
                          .clear();
                      _inventorySections[index]['endingSAController'].clear();
                      _inventorySections[index]['endingWAController'].clear();
                      _inventorySections[index]['beginningController'].clear();
                      _inventorySections[index]['endingController'].clear();
                      _inventorySections[index]['deliveryController'].clear();

                      _inventorySections[index]['selectedNumberOfDaysOOS'] =
                          null;
                      _inventorySections[index]['remarksOOS'] = null;
                      _inventorySections[index]['selectedNoDeliveryOption'] =
                          null;
                      _inventorySections[index]['reasonOOS'] = null;
                      _inventorySections[index]['showNoDeliveryDropdown'] =
                          false;
                      _inventorySections[index]['expiryFields'].clear();

                      // ✅ Only remove the previous SKU if no inventory section is using it
                      if (previousSku != null) {
                        bool isSkuStillUsed = _inventorySections.any(
                            (section) =>
                                section['skuDescription'] == previousSku &&
                                section['versionSelected'] == previousVersion);

                        if (!isSkuStillUsed) {
                          _selectedSkus.remove(previousSku);
                          _disabledSkus.remove(previousSku);
                        }
                      }
                    }

                    // Toggle version selection
                    _inventorySections[index]['versionSelected'] =
                        previousVersion == 'Variant' ? "" : 'Variant';
                  });

                  checkSaveEnabled(); // Ensure save button logic is updated
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    width: 2.0,
                    color: _inventorySections[index]['versionSelected'] ==
                            'Variant'
                        ? Color.fromARGB(255, 26, 20, 71)
                        : Colors.blueGrey.shade200,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text('Variant', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),

        SizedBox(height: 20),

// SKU Description Dropdown (only enabled if V1, V2, or V3 is selected)
        if (['Variant']
            .contains(_inventorySections[index]['versionSelected'])) ...[
          Text(
            'SKU Description',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          DropdownButtonFormField<String>(
            isExpanded: true, // Makes the dropdown use full available width
            value: _inventorySections[index]['skuDescription'] != null &&
                    (_categoryToSkuDescriptions[_inventorySections[index]
                                    ['versionSelected']
                                ?.toString()] ??
                            [])
                        .contains(_inventorySections[index]['skuDescription'])
                ? _inventorySections[index]['skuDescription']
                : null,
            onChanged: (String? newValue) async {
              if (newValue != null && !_selectedSkus.contains(newValue)) {
                _selectSKUnewinventory(newValue, index);
                await _saveSelectedSku(newValue);
              }
            },
            items: (_categoryToSkuDescriptions[_inventorySections[index]
                            ['versionSelected']
                        ?.toString()] ??
                    [])
                .toSet()
                .map<DropdownMenuItem<String>>((String value) {
              bool isMainSelection =
                  value == _inventorySections[index]['skuDescription'];

              // Check if the SKU is selected in any inventory section
              bool isSelectedInInventory = _inventorySections
                  .any((section) => section['skuDescription'] == value);

              // Check if the SKU is disabled or delisted
              bool isDisabled = _disabledSkus.contains(value) ||
                  _delistedSkus.contains(value) ||
                  isSelectedInInventory;

              String displayText = value;
              Color textColor = Colors.black;

              // Apply the selection logic
              if (isMainSelection) {
                displayText = "$value (SELECTED)";
                textColor = Color.fromARGB(255, 26, 20, 71);
              } else if (isSelectedInInventory) {
                // Show which inventory this is selected in
                int inventoryIndex = _inventorySections.indexWhere(
                    (section) => section['skuDescription'] == value);
                displayText = "$value (IN INVENTORY ${inventoryIndex + 2})";
                textColor = Colors.blue;
              } else if (isDisabled) {
                displayText = "$value (DISABLED)";
                textColor = Colors.red;
              }

              return DropdownMenuItem<String>(
                value: value,
                enabled: !isDisabled,
                child: Text(
                  displayText,
                  style: TextStyle(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],

// Product Details and SKU Code (only shown if SKU is selected)
        if (['Variant']
            .contains(_inventorySections[index]['versionSelected'])) ...[
          SizedBox(height: 10),
          Text('Products',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextField(
            controller: _inventorySections[index]['productsController'],
            readOnly: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              hintText: _inventorySections[index]['productDetails'],
            ),
          ),
          SizedBox(height: 10),
          Text('SKU Code',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextField(
            readOnly: true,
            controller: _inventorySections[index]['skuCodeController'],
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              hintText: _inventorySections[index]['skuCode'],
            ),
          ),
        ],

// Status Buttons (only shown if SKU is selected)
        if (_inventorySections[index]['skuDescription'] != null &&
            _inventorySections[index]['skuDescription'].isNotEmpty) ...[
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Carried Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _inventorySections[index]['statusSelected'] =
                          _inventorySections[index]['statusSelected'] ==
                                  'Carried'
                              ? null // ✅ Toggle off if already selected
                              : 'Carried';
                    });
                    _toggleCarriedTextField('Carried', index);
                    checkSaveEnabled();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      width: 2.0,
                      color: _inventorySections[index]['statusSelected'] ==
                              'Carried'
                          ? Color.fromARGB(255, 26, 20, 71)
                          : Colors.blueGrey.shade200,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text('Carried', style: TextStyle(color: Colors.black)),
                ),
              ),
              SizedBox(width: 8),
              // Not Carried Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _inventorySections[index]['statusSelected'] =
                          _inventorySections[index]['statusSelected'] ==
                                  'Not Carried'
                              ? null // ✅ Toggle off if already selected
                              : 'Not Carried';
                    });
                    _toggleCarriedTextField('Not Carried', index);
                    checkSaveEnabled();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      width: 2.0,
                      color: _inventorySections[index]['statusSelected'] ==
                              'Not Carried'
                          ? Color.fromARGB(255, 26, 20, 71)
                          : Colors.blueGrey.shade200,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text('Not Carried',
                      style: TextStyle(color: Colors.black)),
                ),
              ),
              SizedBox(width: 8),
              // Delisted Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _inventorySections[index]['statusSelected'] =
                          _inventorySections[index]['statusSelected'] ==
                                  'Delisted'
                              ? null // ✅ Toggle off if already selected
                              : 'Delisted';
                    });
                    _toggleCarriedTextField('Delisted', index);
                    checkSaveEnabled();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      width: 2.0,
                      color: _inventorySections[index]['statusSelected'] ==
                              'Delisted'
                          ? Color.fromARGB(255, 26, 20, 71)
                          : Colors.blueGrey.shade200,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child:
                      Text('Delisted', style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ],

        // Beginning and Ending Fields
        if (_inventorySections[index]['statusSelected'] == 'Carried') ...[
          SizedBox(height: 15),
          Text(
            'Beginning PCS (Selling Area)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _inventorySections[index]['beginningSAController'],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) {
              _calculateBeginning(index); // Calculate on change
              checkSaveEnabled(); // Call here
            },
          ),
          SizedBox(height: 10),
          Text(
            'Beginning PCS (Warehouse Area)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _inventorySections[index]['beginningWAController'],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) {
              _calculateBeginning(index); // Calculate on change
              checkSaveEnabled(); // Call here
            },
          ),
          SizedBox(height: 10),
          Text(
            'Ending PCS (Selling Area)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _inventorySections[index]['endingSAController'],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) {
              _calculateEnding(index); // Calculate on change
              checkSaveEnabled(); // Call here
            },
          ),
          SizedBox(height: 10),
          Text(
            'Ending PCS (Warehouse Area)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _inventorySections[index]['endingWAController'],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) {
              _calculateEnding(index); // Calculate on change
              checkSaveEnabled(); // Call here
            },
          ),
          SizedBox(height: 10),
          Text(
            'Beginning',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          TextField(
            readOnly: true,
            controller: _inventorySections[index]['beginningController'],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) => checkSaveEnabled(), // Call here
          ),
          SizedBox(height: 10),
          Text(
            'Ending',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          TextField(
            readOnly: true,
            controller: _inventorySections[index]['endingController'],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) => checkSaveEnabled(), // Call here
          ),
        ],

        // Delivery, Offtake, and Inventory Days Level
        if (_inventorySections[index]['statusSelected'] == 'Carried') ...[
          SizedBox(height: 10),
          Text(
            'Delivery PCS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _inventorySections[index]['deliveryController'],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) => checkSaveEnabled(), // Call here
          ),
          SizedBox(height: 10),
          Text(
            'Offtake',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _inventorySections[index]['offtakeController'],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            readOnly: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Inventory Days Level',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _inventorySections[index]
                ['inventoryDaysLevelController'],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            readOnly: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],

        if (_inventorySections[index]['statusSelected'] == 'Carried') ...[
          SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 450,
              child: OutlinedButton(
                onPressed: () =>
                    _addExpiryField(index), // Pass the section index
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      width: 2.0, color: Color.fromARGB(255, 26, 20, 71)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  'Add Expiry',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          if (_inventorySections[index]['expiryFields'].isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0;
                    i < _inventorySections[index]['expiryFields'].length;
                    i++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                          child: _inventorySections[index]['expiryFields'][i]),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _removeExpiryField(
                              index, i); // Pass the section index
                          checkSaveEnabled(); // Call here
                        },
                      ),
                    ],
                  ),
              ],
            ),
        ],

        // No. of Days OOS, Remarks, and Reason
        if (_inventorySections[index]['statusSelected'] == 'Carried') ...[
          SizedBox(height: 10),
          Text(
            'No. of Days OOS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            value: _inventorySections[index]['selectedNumberOfDaysOOS'],
            onChanged: (newValue) {
              setState(() {
                _inventorySections[index]['selectedNumberOfDaysOOS'] = newValue;
                _inventorySections[index]['remarksOOS'] = null;
                _inventorySections[index]['selectedNoDeliveryOption'] = null;
                _inventorySections[index]['reasonOOS'] = null;
                _inventorySections[index]['showNoDeliveryDropdown'] =
                    newValue != 0;
                checkSaveEnabled(); // Call here
              });
            },
            items: List.generate(8, (index) {
              return DropdownMenuItem<int>(
                value: index,
                child: Text(index.toString()),
              );
            }),
          ),
          SizedBox(height: 10),
          if (_inventorySections[index]['selectedNumberOfDaysOOS'] != null &&
              _inventorySections[index]['selectedNumberOfDaysOOS']! > 0) ...[
            Text(
              'Remarks',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              value: _inventorySections[index]['remarksOOS'],
              onChanged: (newValue) {
                setState(() {
                  _inventorySections[index]['remarksOOS'] = newValue;
                  _inventorySections[index]['showNoDeliveryDropdown'] =
                      newValue == 'No Delivery';
                  checkSaveEnabled(); // Call here
                });
              },
              items: [
                DropdownMenuItem<String>(
                  value: 'No P.O',
                  child: Text('No P.O'),
                ),
                DropdownMenuItem<String>(
                  value: 'Unserved',
                  child: Text('Unserved'),
                ),
                DropdownMenuItem<String>(
                  value: 'No Delivery',
                  child: Text('No Delivery'),
                ),
              ],
            ),
            SizedBox(height: 10),
            if (_inventorySections[index]['showNoDeliveryDropdown'] &&
                _inventorySections[index]['selectedNumberOfDaysOOS']! > 0) ...[
              Text(
                'Reason',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                value: _inventorySections[index]['selectedNoDeliveryOption'],
                onChanged: (newValue) {
                  setState(() {
                    _inventorySections[index]['selectedNoDeliveryOption'] =
                        newValue;
                    _inventorySections[index]['reasonOOS'] = newValue;
                    checkSaveEnabled(); // Call here
                  });
                },
                items: [
                  DropdownMenuItem<String>(
                    value: 'With S.O but without P.O',
                    child: Text('With S.O but without P.O'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'With P.O but without Delivery',
                    child: Text('With P.O but without Delivery'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'AR ISSUES',
                    child: Text('AR ISSUES'),
                  ),
                ],
              ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildDropdown(
    String title,
    ValueChanged<String?> onSelect,
    List<String> options,
    InputDecoration Decoration,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DropdownButton<String>(
          value: _selectedDropdownValue,
          isExpanded: true,
          onChanged: onSelect,
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ExpiryField extends StatefulWidget {
  final int index;
  final Function(String, int, int) onExpiryFieldChanged;
  final VoidCallback onDeletePressed;
  final String? initialDate; // Initial value for the selected date
  final int? initialPcs; // Nullable initial value for the TextField

  ExpiryField({
    required this.index,
    required this.onExpiryFieldChanged,
    required this.onDeletePressed,
    this.initialDate,
    this.initialPcs,
  });

  @override
  _ExpiryFieldState createState() => _ExpiryFieldState();
}

class _ExpiryFieldState extends State<ExpiryField> {
  String? _selectedDate;
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _dateController =
      TextEditingController(); // Controller for date field
  bool _isDateSelected = false; // Track date selection

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.initialDate;
    if (widget.initialPcs != null) {
      _expiryController.text = widget.initialPcs.toString();
    }
    if (_selectedDate != null) {
      _dateController.text = _selectedDate!;
      _isDateSelected = true;
    }

    _expiryController.addListener(_onExpiryFieldChanged);
  }

  @override
  void dispose() {
    _expiryController.removeListener(_onExpiryFieldChanged);
    _expiryController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _onExpiryFieldChanged() {
    if (_isDateSelected) {
      widget.onExpiryFieldChanged(
        _selectedDate!,
        int.tryParse(_expiryController.text) ?? 0,
        widget.index,
      );
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate:
          DateTime.now().add(Duration(days: 365 * 5)), // Up to 5 years ahead
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = _formatDate(pickedDate);
        _dateController.text = _selectedDate!;
        _isDateSelected = true;
        _onExpiryFieldChanged();
      });
    }
  }

  String _formatDate(DateTime date) {
    String day = date.day.toString().padLeft(2, '0'); // Two-digit day
    String month = DateFormat('MMM')
        .format(date)
        .toUpperCase(); // Get month abbreviation in uppercase
    String year =
        date.year.toString().substring(2); // Last two digits of the year
    return '$day$month$year';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(
          'Expiry Date',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _dateController,
          readOnly: true, // Prevent manual input
          decoration: InputDecoration(
            hintText: 'Select Expiry Date',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
            suffixIcon: Icon(Icons.calendar_today),
          ),
          onTap: _pickDate, // Open date picker
        ),
        SizedBox(height: 16),
        Text(
          'PCS of Expiry',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _expiryController,
          enabled:
              _isDateSelected, // Enable TextField only when a date is selected
          decoration: InputDecoration(
            hintText: 'Enter PCS of expiry',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _onExpiryFieldChanged();
          },
        ),
      ],
    );
  }
}

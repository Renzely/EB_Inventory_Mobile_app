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

  List<DropdownMenuItem<String>> _getFilteredPeriodItems() {
    List<DropdownMenuItem<String>> items = [];

    // Get current date or use the override date if set
    DateTime currentDate = getCurrentWeekStartDate();

    List<List<DateTime>> periods = [
      [
        DateTime(2024, 10, 12),
        DateTime(2024, 10, 21)
      ], // Actual range: Oct 12 - Oct 20 (labeled as Oct 12 - Oct 18)
      [
        DateTime(2024, 10, 19),
        DateTime(2024, 10, 28)
      ], // Actual range: Oct 19 - Oct 27 (labeled as Oct 19 - Oct 25)
      [
        DateTime(2024, 10, 26),
        DateTime(2024, 11, 4)
      ], // Actual range: Oct 26 - Nov 3 (labeled as Oct 26 - Nov 1)
      [
        DateTime(2024, 11, 2),
        DateTime(2024, 11, 11)
      ], // Actual range: Nov 2 - Nov 10 (labeled as Nov 2 - Nov 8)
      [
        DateTime(2024, 11, 9),
        DateTime(2024, 11, 18)
      ], // Actual range: Nov 9 - Nov 17 (labeled as Nov 9 - Nov 15)
      [
        DateTime(2024, 11, 16),
        DateTime(2024, 11, 25)
      ], // Actual range: Nov 16 - Nov 24 (labeled as Nov 16 - Nov 22)
      [
        DateTime(2024, 11, 23),
        DateTime(2024, 12, 2)
      ], // Actual range: Nov 23 - Dec 1 (labeled as Nov 23 - Nov 29)
      [
        DateTime(2024, 11, 30),
        DateTime(2024, 12, 9)
      ], // Actual range: Nov 30 - Dec 8 (labeled as Nov 30 - Dec 6)
      [
        DateTime(2024, 12, 7),
        DateTime(2024, 12, 16)
      ], // Actual range: Dec 7 - Dec 15 (labeled as Dec 7 - Dec 13)
      [
        DateTime(2024, 12, 14),
        DateTime(2024, 12, 23)
      ], // Actual range: Dec 14 - Dec 22 (labeled as Dec 14 - Dec 20)
      [
        DateTime(2024, 12, 21),
        DateTime(2024, 12, 30)
      ], // Actual range: Dec 21 - Dec 29 (labeled as Dec 21 - Dec 27)
    ];
    List<DateTime> currentPeriod = periods.firstWhere(
        (period) =>
            currentDate.isAfter(period[0]) && currentDate.isBefore(period[1]),
        orElse: () =>
            [DateTime(0), DateTime(0)] // return a default empty period
        );

    if (currentPeriod.isNotEmpty) {
      // Proceed with currentPeriod logic
      String periodString =
          '${DateFormat('MMMdd').format(currentPeriod[0])}-${DateFormat('MMMdd').format(currentPeriod[1].subtract(Duration(days: 3)))}';
      items.add(
          DropdownMenuItem(child: Text(periodString), value: periodString));
      print("Selected period: ${currentPeriod[0]} - ${currentPeriod[1]}");
    } else {
      // Handle the case where no period is found
      print("No matching period found.");
    }

    return items;
  }

  DateTime getCurrentWeekStartDate({DateTime? overrideDate}) {
    // Use the overrideDate if provided, otherwise use the actual current date
    var now = overrideDate ?? DateTime.now();
    var today = DateTime(now.year, now.month, now.day);
    var firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));
    return firstDayOfWeek;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.grey[600],
                elevation: 0,
                title: Text(
                  'Inventory Input',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
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
                                                  String actualValue =
                                                      value.split('-')[1];
                                                  print(
                                                      'Selected period: $value');
                                                  switch (actualValue) {
                                                    case 'Oct18':
                                                      _monthController.text =
                                                          'October';
                                                      _weekController.text =
                                                          'Week 42';
                                                      break;
                                                    case 'Oct25':
                                                      _monthController.text =
                                                          'October';
                                                      _weekController.text =
                                                          'Week 43';
                                                      break;
                                                    case 'Nov01':
                                                      _monthController.text =
                                                          'November';
                                                      _weekController.text =
                                                          'Week 44';
                                                      break;
                                                    case 'Nov08':
                                                      _monthController.text =
                                                          'November';
                                                      _weekController.text =
                                                          'Week 45';
                                                      break;
                                                    case 'Nov15':
                                                      _monthController.text =
                                                          'November';
                                                      _weekController.text =
                                                          'Week 46';
                                                      break;
                                                    case 'Nov22':
                                                      _monthController.text =
                                                          'November';
                                                      _weekController.text =
                                                          'Week 47';
                                                      break;
                                                    case 'Nov29':
                                                      _monthController.text =
                                                          'November';
                                                      _weekController.text =
                                                          'Week 48';
                                                      break;
                                                    case 'Dec06':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 49';
                                                      break;
                                                    case 'Dec13':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 50';
                                                      break;
                                                    case 'Dec20':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 51';
                                                      break;
                                                    case 'Dec27':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 52';
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
                                              Colors.grey)),
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
                                            Colors.grey)
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
  String _inputid = '';
  int? _selectedNumberOfDaysOOS;
  bool _showCarriedTextField = false;
  bool _showNotCarriedTextField = false;
  bool _showDelistedTextField = false;
  bool _isSaveEnabled = false;
  bool _isEditing = true;
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
  List<String> _disabledSkus = [];

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

    InventoryItem newItem = InventoryItem(
      id: ObjectId(), // Generate this as needed
      userEmail: widget.userEmail,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()), // Current date
      inputId: inputid,
      name: '${widget.userName} ${widget.userLastName}',
      accountNameBranchManning: widget.selectedAccount,
      period: widget.SelectedPeriod,
      month: widget.selectedMonth,
      week: widget.selectedWeek,
      category: Version,
      skuDescription: SKUDescription,
      products: product,
      skuCode: skucode,
      status: status,
      beginning: beginningValue,
      beginningSA: beginningSAValue,
      beginningWA: beginningWAValue,
      delivery: deliveryValue,
      ending: endingValue,
      endingSA: endingSAValue,
      endingWA: endingWAValue,
      offtake: offtakeValue,
      inventoryDaysLevel: inventoryDaysLevel.toDouble(),
      noOfDaysOOS: noOfDaysOOSValue,
      expiryFields: _expiryFieldsValues,
      remarksOOS: remarksOOS,
      reasonOOS: reasonOOS,
      isEditing: true, // Set to false when saving new item
    );

    await _saveToDatabase(newItem);

    // Update status of the original item if editing
    if (_isEditing) {
      await _updateEditingStatus(inputid, widget.userEmail, false);
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

  Future<List<InventoryItem>> getUserInventoryItems(String userEmail) async {
    List<InventoryItem> items = [];
    try {
      final db = await mongo.Db.create(INVENTORY_CONN_URL);
      await db.open();
      final collection = db.collection(USER_INVENTORY);
      final result = await collection.find({'userEmail': userEmail}).toList();

      for (var doc in result) {
        items.add(InventoryItem.fromJson(doc));
      }

      await db.close();
    } catch (e) {
      print('Error fetching inventory items: $e');
    }
    return items;
  }

  void _addExpiryField() {
    setState(() {
      if (_expiryFields.length < 6) {
        int index = _expiryFields.length;
        _expiryFields.add(
          ExpiryField(
            index: index,
            onExpiryFieldChanged: (month, pcs, index) {
              _updateExpiryField(
                  index, {'expiryMonth': month, 'expiryPcs': pcs});
            },
            onDeletePressed: () {
              _removeExpiryField(index);
            },
          ),
        );
        _expiryFieldsValues.add({'expiryMonth': '', 'expiryPcs': 0});
      }
    });
  }

  void _removeExpiryField(int index) {
    setState(() {
      _expiryFields.removeAt(index);
      _expiryFieldsValues.removeAt(index);

      // Update the index of remaining fields
      for (int i = index; i < _expiryFields.length; i++) {
        _expiryFields[i] = ExpiryField(
          index: i,
          onExpiryFieldChanged: (month, pcs, index) {
            _updateExpiryField(index, {'expiryMonth': month, 'expiryPcs': pcs});
          },
          onDeletePressed: () {
            _removeExpiryField(i);
          },
        );
      }
    });
  }

  void _updateExpiryField(int index, Map<String, dynamic> newValue) {
    setState(() {
      _expiryFieldsValues[index] = newValue;
    });
  }

  Map<String, List<String>> _categoryToSkuDescriptions = {
    'V1': [
      "KOPIKO COFFEE CANDY 24X175G",
      "KOPIKO COFFEE CANDY JAR 6X560G",
      "KOPIKO CAPPUCCINO CANDY 24X175G",
      "FRES BARLEY MINT 24X50X3G",
      "FRES MINT BARLEY JAR 12X200X3G",
      "FRES CHERRY CANDY, 24 X 50 X 3G",
      "FRES CHERRY JAR, 12X 200 X 3G",
      "FRES GRAPE CANDY, 24 X 50 X 3G",
      "FRES GRAPE JAR, 12 X 200 X 3G",
      "FRES APPLE PEACH 24 X 50 X 3G",
      "BENG BENG CHOCOLATE 12 X 10 X 26.5G",
      "BENG BENG SHARE IT 16 X 95G",
      "CAL CHEESE 10X20X8.5G",
      "CAL CHEESE 60X35G",
      "CAL CHEESE 60X53.5G",
      "CAL CHEESE CHEESE CHOCO 60X53.5G",
      "CAL CHEESE CHEESE CHOCO 60X35G",
      "MALKIST CHOCOLATE 30X10X18G",
      "WAFELLO CHOCOLATE WAFER 60X53.5G",
      "WAFELLO CHOCOLATE WAFER 60X35G",
      "WAFELLO BUTTER CARAMEL 60X35G",
      "WAFELLO COCO CREME 60X35G",
      "WAFELLO CREAMY VANILLA 20X10X20.5G PH",
      "VALMER CHOCOLATE 12X10X54G",
      "SUPERSTAR TRIPLE CHOCOLATE 12 X10 X 18G",
      "DANISA BUTTER COOKIES 12X454G",
      "WAFELLO BUTTER CARAMEL 60X53.5G",
      "WAFELLO COCO CREME 60X53.5G",
      "WAFELLO CHOCOLATE 48G X 60",
      "WAFELLO CHOCOLATE 21G X 10 X 20",
      "WAFELLO BUTTER CARAMEL 48G X 60",
      "WAFELLO BUTTER CARAMEL 20.5G X 10 X 20",
      "WAFELLO COCO CRÈME 48G X 60",
      "WAFELLO COCONUT CRÈME 20.5G X 10 X 20",
      "CAL CHEESE 60 X 48G",
      "CAL CHEESE 20 X 10 X 20G",
      "CAL CHEESE 20 X 20 X 8.5G",
      "CAL CHEESE CHOCO 60 X 48G",
      "CAL CHEESE CHOCO 20 X 10 X 20.5G",
      "VALMER SANDWICH CHOCOLATE 12X10X36G",
      "MALKIST CAPPUCCINO 30X10X18G PH",
      "FRES CHERRY JAR PROMO",
      "FRES BARLEY JAR PROMO",
      "FRES GRAPE JAR PROMO",
      "FRES MIX CANDY JAR PROMO",
      "CAL CHEESE 20G (9+1 PROMO)",
      "WAFELLO CHOCOLATE 21G (9+1 PROMO)",
      "WAFELLO COCO CREME 20.5G (9+1 PROMO)",
      "WAFELLO BUTTER CARAMEL 20.5G (9+1 PROMO)",
      "FRES MIXED CANDY JAR 12 X 600G",
      "WAFELLO CREAMY VANILLA 60X48G PH",
      "MALKIST SWEET GLAZED 12X10X28G PH",
      "MALKIST BARBECUE 12X10X28G PH"
    ],
    'V2': [
      "Kopiko Black 3 in One Hanger 24 x 10 x 30g",
      "KOPIKO BLACK 3-IN-1 BAG 8 X 30 X 30G",
      "Kopiko Black 3 in One Promo Twin 12 x 10 x 2 x 30g",
      "Kopiko Brown Coffee hg 27.5g 24x10x27.5g",
      "Kopiko Brown Coffee Pouch 24x10x27.5g",
      "Kopiko Brown Coffee Bag 8x30x27.5g",
      "Kopiko Brown Promo Twin 12 x 10 x 53g",
      "Kopiko Cappuccino Hanger 24 x 10 x 25g",
      "Kopiko Cappuccino Pouch 24x10x25g",
      "Kopiko Cappuccino Bag 8x30x25g",
      "Kopiko L.A. Coffee hanger 24x10x25g",
      "Kopiko LA Coffee Pouch 24x10x25g",
      "Kopiko Blanca hanger 24x10x30g",
      "KOPIKO BLANCA, POUCH 24 X 10 X 30G",
      "KOPIKO BLANCA, BAG 8 X 30 X 30G",
      "Kopiko Blanca Twinpack 12 X 10 X 2 X 29G",
      "Toracafe White and Creamy 12 X (10 X 2) X 26G",
      "Kopiko Creamy Caramelo 12 x (10 x 2) x 25g",
      "Kopiko Double Cups 24 x 10 x 36g",
      "ENERGEN CHOCOLATE HANGER 24 X 10 X 40G",
      "Energen Chocolate Pouch 24x10x40g",
      "Energen Chocolate Bag 8x30x40g",
      "ENERGEN VANILLA HANGER 24 X 10 X 40G",
      "Energen Vanilla Pouch 24x10x40g",
      "Energen Vanilla Bag 8x30x40g",
      "Energen Champion NBA Hanger 24 x 10 x 35g",
      "Energen Pandesal Mate 24 x 10 x 30g",
      "ENERGEN CHAMPION 12X10X2X35G PH",
      "Kopiko Cafe Mocha TP 12X10X(2X25.5G) PH",
      "Energen Champion NBA TP 15 x 8 x 2 x30g ph",
      "KOPIKO BLACK 3IN1 TWINPACK 12X10X2X28G",
      "KOPIKO BLACK 3IN1 HANGER 24X10X30G UNLI",
      "KOPIKO BLACK 3IN1 TP 12X10X2X28G UNLI",
      "KOPIKO BROWN HANGER 24X10X27.5G UNLI",
      "KOPIKO BROWN TP 12X10X2X26.5G UNLI",
      "CHAMPION HANGER 17+3",
      "Champion Twin Pack 13+3",
      "Kopiko Blanca TP Banded 6 x (18 + 2) x 2 x 29g",
      "KOPIKO BROWN COFFEE TWINPACK BUY 12 SAVE 13 PROMO",
      "KOPIKO BLACK TWIN BUY 10 SAVE 13",
      "KOPIKO BLANCA HANGER GSK 12 X 2 X 10 X 30G",
      "BLANCA TP 10+1",
      "Champion Hanger 20x(10+2) x 35g/30g",
      "ENERGEN CHAMPION 40X345G",
      "KOPIKO BLACK 3-IN-1 POUCH 24 X 10 X 30G"
    ],
    'V3': [
      "Le Minerale 24x330ml",
      "Le Minerale 24x600ml",
      "Le Minerale 12x1500ml",
      "LE MINERALE 4 X 5000ML",
      "KOPIKO LUCKY DAY 24BTL X 180ML",
      "KLD 5+1 Bundling"
    ],
  };

  Map<String, Map<String, String>> _skuToProductSkuCode = {
    //CATEGORY V1

    'KOPIKO COFFEE CANDY 24X175G': {'Product': ' ', 'SKU Code': '326924'},
    'KOPIKO COFFEE CANDY JAR 6X560G': {'Product': ' ', 'SKU Code': '329106'},
    'KOPIKO CAPPUCCINO CANDY 24X175G': {'Product': ' ', 'SKU Code': '326925'},
    'FRES BARLEY MINT 24X50X3G': {'Product': ' ', 'SKU Code': '326446'},
    'FRES MINT BARLEY JAR 12X200X3G': {'Product': ' ', 'SKU Code': '329136'},
    'FRES CHERRY CANDY, 24 X 50 X 3G': {'Product': ' ', 'SKU Code': '326447'},
    'FRES CHERRY JAR, 12X 200 X 3G': {'Product': ' ', 'SKU Code': '329135'},
    'FRES GRAPE CANDY, 24 X 50 X 3G': {'Product': ' ', 'SKU Code': '326448'},
    'FRES GRAPE JAR, 12 X 200 X 3G': {'Product': ' ', 'SKU Code': '329137'},
    'FRES APPLE PEACH 24 X 50 X 3G': {'Product': ' ', 'SKU Code': '329545'},
    'BENG BENG CHOCOLATE 12 X 10 X 26.5G': {
      'Product': ' ',
      'SKU Code': '329067'
    },
    'BENG BENG SHARE IT 16 X 95G': {'Product': ' ', 'SKU Code': '322583'},
    'CAL CHEESE 10X20X8.5G': {'Product': ' ', 'SKU Code': '330071'},
    'CAL CHEESE 60X35G': {'Product': ' ', 'SKU Code': '322571'},
    'CAL CHEESE 60X53.5G': {'Product': ' ', 'SKU Code': '329808'},
    'CAL CHEESE CHEESE CHOCO 60X53.5G': {'Product': ' ', 'SKU Code': '322866'},
    'CAL CHEESE CHEESE CHOCO 60X35G': {'Product': ' ', 'SKU Code': '322867'},
    'MALKIST CHOCOLATE 30X10X18G': {'Product': ' ', 'SKU Code': '321036'},
    'WAFELLO CHOCOLATE WAFER 60X53.5G': {'Product': ' ', 'SKU Code': '330016'},
    'WAFELLO CHOCOLATE WAFER 60X35G': {'Product': ' ', 'SKU Code': '330025'},
    'WAFELLO BUTTER CARAMEL 60X35G': {'Product': ' ', 'SKU Code': '322871'},
    'WAFELLO COCO CREME 60X35G': {'Product': ' ', 'SKU Code': '322868'},
    'WAFELLO CREAMY VANILLA 20X10X20.5G PH': {
      'Product': ' ',
      'SKU Code': '330073'
    },
    'VALMER CHOCOLATE 12X10X54G': {'Product': ' ', 'SKU Code': '321038'},
    'SUPERSTAR TRIPLE CHOCOLATE 12 X10 X 18G': {
      'Product': ' ',
      'SKU Code': '322894'
    },
    'DANISA BUTTER COOKIES 12X454G': {'Product': ' ', 'SKU Code': '329650'},
    'WAFELLO BUTTER CARAMEL 60X53.5G': {'Product': ' ', 'SKU Code': '322870'},
    'WAFELLO COCO CREME 60X53.5G': {'Product': ' ', 'SKU Code': '322869'},
    'WAFELLO CHOCOLATE 48G X 60': {'Product': ' ', 'SKU Code': '330050'},
    'WAFELLO CHOCOLATE 21G X 10 X 20': {'Product': ' ', 'SKU Code': '330051'},
    'WAFELLO BUTTER CARAMEL 48G X 60': {'Product': ' ', 'SKU Code': '330056'},
    'WAFELLO BUTTER CARAMEL 20.5G X 10 X 20': {
      'Product': ' ',
      'SKU Code': '330057'
    },
    'WAFELLO COCO CRÈME 48G X 60': {'Product': ' ', 'SKU Code': '330058'},
    'WAFELLO COCONUT CRÈME 20.5G X 10 X 20': {
      'Product': ' ',
      'SKU Code': '330059'
    },
    'CAL CHEESE 60 X 48G': {'Product': ' ', 'SKU Code': '330052'},
    'CAL CHEESE 20 X 10 X 20G': {'Product': ' ', 'SKU Code': '330053'},
    'CAL CHEESE 20 X 20 X 8.5G': {'Product': ' ', 'SKU Code': '330071'},
    'CAL CHEESE CHOCO 60 X 48G': {'Product': ' ', 'SKU Code': '330054'},
    'CAL CHEESE CHOCO 20 X 10 X 20.5G': {'Product': ' ', 'SKU Code': '330055'},
    'VALMER SANDWICH CHOCOLATE 12X10X36G': {
      'Product': ' ',
      'SKU Code': '321475'
    },
    'MALKIST CAPPUCCINO 30X10X18G PH': {'Product': ' ', 'SKU Code': '31446'},
    'FRES CHERRY JAR PROMO': {'Product': ' ', 'SKU Code': 'P-2023-07-329135'},
    'FRES BARLEY JAR PROMO': {'Product': ' ', 'SKU Code': 'P-2023-07-329106'},
    'FRES GRAPE JAR PROMO': {'Product': ' ', 'SKU Code': 'P-2023-07-329137'},
    'FRES MIX CANDY JAR PROMO': {
      'Product': ' ',
      'SKU Code': 'P-2023-07-320015'
    },
    'CAL CHEESE 20G (9+1 PROMO)': {
      'Product': ' ',
      'SKU Code': 'P-2022-12-322571'
    },
    'WAFELLO CHOCOLATE 21G (9+1 PROMO)': {
      'Product': ' ',
      'SKU Code': 'P-2022-12-330051'
    },
    'WAFELLO COCO CREME 20.5G (9+1 PROMO)': {
      'Product': ' ',
      'SKU Code': 'P-2022-12-330059'
    },
    'WAFELLO BUTTER CARAMEL 20.5G (9+1 PROMO)': {
      'Product': ' ',
      'SKU Code': 'P-2022-12-330057'
    },
    'FRES MIXED CANDY JAR 12 X 600G': {'Product': ' ', 'SKU Code': '320015'},
    'WAFELLO CREAMY VANILLA 60X48G PH': {'Product': ' ', 'SKU Code': '330060'},
    'MALKIST SWEET GLAZED 12X10X28G PH': {'Product': ' ', 'SKU Code': '420559'},
    'MALKIST BARBECUE 12X10X28G PH': {'Product': ' ', 'SKU Code': '420558'},

    //CATEGORY V2

    'Kopiko Black 3 in One Hanger 24 x 10 x 30g': {
      'Product': ' ',
      'SKU Code': '322628'
    },
    'KOPIKO BLACK 3-IN-1 BAG 8 X 30 X 30G': {
      'Product': ' ',
      'SKU Code': '322629'
    },
    'Kopiko Black 3 in One Promo Twin 12 x 10 x 2 x 30g': {
      'Product': ' ',
      'SKU Code': '322627'
    },
    'Kopiko Brown Coffee hg 27.5g 24x10x27.5g': {
      'Product': ' ',
      'SKU Code': '328890'
    },
    'Kopiko Brown Coffee Pouch 24x10x27.5g': {
      'Product': ' ',
      'SKU Code': '328883'
    },
    'Kopiko Brown Coffee Bag 8x30x27.5g': {
      'Product': ' ',
      'SKU Code': '328882'
    },
    'Kopiko Brown Promo Twin 12 x 10 x 53g': {
      'Product': ' ',
      'SKU Code': '329479'
    },
    'Kopiko Cappuccino Hanger 24 x 10 x 25g': {
      'Product': ' ',
      'SKU Code': '329701'
    },
    'Kopiko Cappuccino Pouch 24x10x25g': {'Product': ' ', 'SKU Code': '329703'},
    'Kopiko Cappuccino Bag 8x30x25g': {'Product': ' ', 'SKU Code': '329704'},
    'Kopiko L.A. Coffee hanger 24x10x25g': {
      'Product': ' ',
      'SKU Code': '325666'
    },
    'Kopiko LA Coffee Pouch 24x10x25g': {'Product': ' ', 'SKU Code': '325667'},
    'Kopiko Blanca hanger 24x10x30g': {'Product': ' ', 'SKU Code': '328888'},
    'KOPIKO BLANCA, POUCH 24 X 10 X 30G': {
      'Product': ' ',
      'SKU Code': '328887'
    },
    'KOPIKO BLANCA, BAG 8 X 30 X 30G': {'Product': ' ', 'SKU Code': '328889'},
    'Kopiko Blanca Twinpack 12 X 10 X 2 X 29G': {
      'Product': ' ',
      'SKU Code': '322711'
    },
    'Toracafe White and Creamy 12 X (10 X 2) X 26G': {
      'Product': ' ',
      'SKU Code': '322731'
    },
    'Kopiko Creamy Caramelo 12 x (10 x 2) x 25g': {
      'Product': ' ',
      'SKU Code': '322725'
    },
    'Kopiko Double Cups 24 x 10 x 36g': {'Product': ' ', 'SKU Code': '329744'},
    'ENERGEN CHOCOLATE HANGER 24 X 10 X 40G': {
      'Product': ' ',
      'SKU Code': '328497'
    },
    'Energen Chocolate Pouch 24x10x40g': {'Product': ' ', 'SKU Code': '328492'},
    'Energen Chocolate Bag 8x30x40g': {'Product': ' ', 'SKU Code': '328493'},
    'ENERGEN VANILLA HANGER 24 X 10 X 40G': {
      'Product': ' ',
      'SKU Code': '328494'
    },
    'Energen Vanilla Pouch 24x10x40g': {'Product': ' ', 'SKU Code': '328495'},
    'Energen Vanilla Bag 8x30x40g': {'Product': ' ', 'SKU Code': '328496'},
    'Energen Champion NBA Hanger 24 x 10 x 35g': {
      'Product': ' ',
      'SKU Code': '325945'
    },
    'Energen Pandesal Mate 24 x 10 x 30g': {
      'Product': ' ',
      'SKU Code': '325899'
    },
    'ENERGEN CHAMPION 12X10X2X35G PH': {'Product': ' ', 'SKU Code': '325934'},
    'Kopiko Cafe Mocha TP 12X10X(2X25.5G) PH': {
      'Product': ' ',
      'SKU Code': '324149'
    },
    'Energen Champion NBA TP 15 x 8 x 2 x30g ph': {
      'Product': ' ',
      'SKU Code': '325965'
    },
    'KOPIKO BLACK 3IN1 TWINPACK 12X10X2X28G': {
      'Product': ' ',
      'SKU Code': '420011'
    },
    'KOPIKO BLACK 3IN1 HANGER 24X10X30G UNLI': {
      'Product': ' ',
      'SKU Code': '420203'
    },
    'KOPIKO BLACK 3IN1 TP 12X10X2X28G UNLI': {
      'Product': ' ',
      'SKU Code': '420202'
    },
    'KOPIKO BROWN HANGER 24X10X27.5G UNLI': {
      'Product': ' ',
      'SKU Code': '420205'
    },
    'KOPIKO BROWN TP 12X10X2X26.5G UNLI': {
      'Product': ' ',
      'SKU Code': '420204'
    },
    'CHAMPION HANGER 17+3': {'Product': ' ', 'SKU Code': '900082'},
    'Champion Twin Pack 13+3': {'Product': ' ', 'SKU Code': '900083'},
    'Kopiko Blanca TP Banded 6 x (18 + 2) x 2 x 29g': {
      'Product': ' ',
      'SKU Code': '322789'
    },
    'KOPIKO BROWN COFFEE TWINPACK BUY 12 SAVE 13 PROMO': {
      'Product': ' ',
      'SKU Code': 'P-2022-09-329479'
    },
    'KOPIKO BLACK TWIN BUY 10 SAVE 13': {
      'Product': ' ',
      'SKU Code': 'P-2022-09-322627'
    },
    'KOPIKO BLANCA HANGER GSK 12 X 2 X 10 X 30G': {
      'Product': ' ',
      'SKU Code': 'P-2022-11-328888'
    },
    'BLANCA TP 10+1': {'Product': ' ', 'SKU Code': 'PROMO-2023-08-322711'},
    'Champion Hanger 20x(10+2) x 35g/30g': {
      'Product': ' ',
      'SKU Code': 'P-2023-09-900084'
    },
    'ENERGEN CHAMPION 40X345G': {'Product': ' ', 'SKU Code': '420373'},
    'KOPIKO BLACK 3-IN-1 POUCH 24 X 10 X 30G': {
      'Product': ' ',
      'SKU Code': '322630'
    },

    //CATEGORY V3

    'Le Minerale 24x330ml': {'Product': ' ', 'SKU Code': '328566'},
    'Le Minerale 24x600ml': {'Product': ' ', 'SKU Code': '328565'},
    'Le Minerale 12x1500ml': {'Product': ' ', 'SKU Code': '326770'},
    'LE MINERALE 4 X 5000ML': {'Product': ' ', 'SKU Code': '324045'},
    'KOPIKO LUCKY DAY 24BTL X 180ML': {'Product': ' ', 'SKU Code': '324046'},
    'KLD 5+1 Bundling': {'Product': ' ', 'SKU Code': 'P-2022-10-324046'}
  };

  // List<String> getSkuDescriptions(List<String> savedSkus) {
  //   List<String> matchedDescriptions = [];
  //   for (String sku in savedSkus) {
  //     _categoryToSkuDescriptions.forEach((category, SKUDescription) {
  //       if (SKUDescription.contains(sku)) {
  //         matchedDescriptions.add(sku);
  //       }
  //     });
  //   }
  //   return matchedDescriptions;
  // }

  // List<String> getFilteredSkuDescriptions(List<String> savedSkus) {
  //   List<String> matchedDescriptions = [];
  //   _categoryToSkuDescriptions.forEach((category, SKUDescription) {
  //     matchedDescriptions.addAll(SKUDescription.where(
  //         (SKUDescription) => savedSkus.contains(SKUDescription)));
  //   });
  //   return matchedDescriptions;
  // }

  // void loadSkuDescriptions(String branchName, String category) async {
  //   List<Map<String, dynamic>> skus =
  //       await MongoDatabase.getSkusByBranchAndCategory(branchName, category);

  //   print('SKUs by Branch and Category: $skus');

  //   if (skus.isNotEmpty) {
  //     List<String> savedSkus =
  //         skus.map((sku) => sku['SKUs'] as String).toList();
  //     print('Saved SKUs: $savedSkus');

  //     List<String> skuDescriptions = getSkuDescriptions(savedSkus);
  //     print('SKU Descriptions: $skuDescriptions');

  //     setState(() {
  //       _availableSkuDescriptions = skuDescriptions;
  //       _selectedDropdownValue =
  //           skuDescriptions.isNotEmpty ? skuDescriptions.first : null;
  //     });
  //   } else {
  //     setState(() {
  //       _availableSkuDescriptions = [];
  //       _selectedDropdownValue = null;
  //     });
  //     print('No SKUs found for this branch and category.');
  //   }
  // }

  void _toggleDropdown(String version) {
    setState(() {
      if (_versionSelected == version) {
        // If the same dropdown is clicked again, hide it
        _versionSelected = null;
        _isDropdownVisible = false; // Hide the dropdown
      } else {
        // Otherwise, show the clicked dropdown
        _versionSelected = version;
        _isDropdownVisible = true; // Show the dropdown
      }

      // Reset remarks, reason, and their dropdown visibility
      _remarksOOS = null; // Hide the Remarks dropdown
      _selectedNoDeliveryOption = null; // Reset No Delivery option
      _reasonOOS = null; // Reset Reason for OOS
      _showNoDeliveryDropdown = false; // Hide No Delivery reason dropdown

      // Reset No. of Days OOS
      _selectedNumberOfDaysOOS = 0; // Reset Number of Days OOS to 0

      // Reset other fields and visibility states
      _selectedDropdownValue = null;
      _productDetails = null; // Clear product details
      _skuCode = null; // Clear SKU code
      _expiryFields.clear(); // Clear expiry fields when switching categories

      // Hide buttons and text fields when a category is deselected
      _showCarriedTextField = false;
      _showNotCarriedTextField = false;
      _showDelistedTextField = false;

      // Reset text controllers (optional)
      _beginningController.clear();
      _deliveryController.clear();
      _endingController.clear();
      _offtakeController.clear();
    });
  }

  void _selectSKU(String? newValue) {
    if (newValue != null && _skuToProductSkuCode.containsKey(newValue)) {
      setState(() {
        _selectedDropdownValue = newValue;
        _productDetails = _skuToProductSkuCode[newValue]!['Product'];
        _skuCode = _skuToProductSkuCode[newValue]!['SKU Code'];
      });
    }
  }

  void _confirmSave() {
    if (_selectedDropdownValue != null) {
      _saveSelectedSku(_selectedDropdownValue!);
      // Optionally, show a confirmation dialog or message here
    }
  }

  void _toggleCarriedTextField(String status) {
    setState(() {
      _statusSelected = status;
      _showCarriedTextField = true;
      _showNotCarriedTextField = false;
      _showDelistedTextField = false;
      _beginningController.clear();
      _deliveryController.clear();
      _endingController.clear();
      _offtakeController.clear();
      _expiryFields.clear(); // Clear expiry fields when switching categories
    });
  }

  void _toggleNotCarriedTextField(String status) {
    setState(() {
      _statusSelected = status;
      _showCarriedTextField = false;
      _showNotCarriedTextField = true;
      _showDelistedTextField = false;
      _showNoDeliveryDropdown = false;
      _showNoPOTextField = false;
      _showUnservedTextField = false;
      _beginningController.clear();
      _beginningSAController.clear();
      _beginningWAController.clear();
      _deliveryController.clear();
      _endingController.clear();
      _endingSAController.clear();
      _endingWAController.clear();
      _offtakeController.clear();
      _expiryFields.clear(); // Clear expiry fields when switching categories

      if (status == 'Not Carried' || status == 'Delisted') {
        _selectedNumberOfDaysOOS = 0;
      }
    });
  }

  void _toggleDelistedTextField(String status) {
    setState(() {
      _statusSelected = status;
      _showCarriedTextField = false;
      _showNotCarriedTextField = false;
      _showDelistedTextField = true;
      _showNoDeliveryDropdown = false;
      _showNoPOTextField = false;
      _showUnservedTextField = false;
      _beginningSAController.clear();
      _beginningWAController.clear();
      _beginningController.clear();
      _deliveryController.clear();
      _endingController.clear();
      _endingSAController.clear();
      _endingWAController.clear();
      _offtakeController.clear();
      _expiryFields.clear(); // Clear expiry fields when switching categories
      if (status == 'Not Carried' || status == 'Delisted') {
        _selectedNumberOfDaysOOS = 0;
      }
    });
  }

  DateTime _getNextTuesday() {
    DateTime now = DateTime.now();
    int daysUntilNextTuesday = (DateTime.tuesday - now.weekday + 7) % 7;

    // Return the next Tuesday at exactly 12:00 AM
    DateTime nextTuesday = DateTime(now.year, now.month, now.day)
        .add(Duration(days: daysUntilNextTuesday));

    return DateTime(nextTuesday.year, nextTuesday.month, nextTuesday.day, 0, 0,
        0); // 12:00 AM
  }

  Future<void> _saveSelectedSku(String selectedSku) async {
    final prefs = await SharedPreferences.getInstance();
    String branch = widget.selectedAccount;
    String key = 'disabledSkus_$branch';

    // Load current disabled SKUs
    String? disabledSkusData = prefs.getString(key);
    List<String> currentDisabledSkus = [];

    if (disabledSkusData != null) {
      Map<String, dynamic> storedData = jsonDecode(disabledSkusData);
      currentDisabledSkus = List<String>.from(storedData['skus']);
      DateTime expirationDate = DateTime.parse(storedData['expiration']);
      DateTime now = DateTime.now();

      // Check if we are exactly at 12:00 AM on Tuesday
      if (now.weekday == DateTime.tuesday && now.hour == 0 && now.minute == 0) {
        // It's exactly 12:00 AM on Tuesday, reset SKUs
        print("It's 12:00 AM Tuesday, resetting SKUs.");
        currentDisabledSkus.clear();
        prefs.remove(key); // Clear the prefs as well
      } else if (now.isAfter(expirationDate)) {
        // If it's past expiration, do NOT reset the SKUs
        print("Current time is past expiration but not resetting SKUs.");
      }
    }

    // Add the new SKU to the list if it's not already there
    if (!currentDisabledSkus.contains(selectedSku)) {
      setState(() {
        currentDisabledSkus.add(selectedSku);
        _disabledSkus = currentDisabledSkus; // Update the state
      });
    } else {
      print("SKU $selectedSku is already disabled.");
    }

    // Save the updated SKUs with new expiration
    DateTime nextTuesday = _getNextTuesday();
    Map<String, dynamic> dataToStore = {
      'expiration': nextTuesday.toIso8601String(),
      'skus': _disabledSkus,
    };

    String jsonData = jsonEncode(dataToStore);
    await prefs.setString(key, jsonData);

    print("SKUs saved: $_disabledSkus");

    // Force reload after saving
    await _loadDisabledSkus();
  }

  Future<void> _loadDisabledSkus() async {
    final prefs = await SharedPreferences.getInstance();
    String branch = widget.selectedAccount;
    String key = 'disabledSkus_$branch';

    String? disabledSkusData = prefs.getString(key);

    if (disabledSkusData == null) {
      print("No disabled SKUs found for branch: $branch");
      _disabledSkus.clear();
      return;
    }

    try {
      Map<String, dynamic> storedData = jsonDecode(disabledSkusData);
      DateTime expirationDate = DateTime.parse(storedData['expiration']);
      DateTime now = DateTime.now();

      print("Loading disabled SKUs. Expiration Date: $expirationDate");
      print("Current Date: $now");

      // Only reset if it's exactly 12:00 AM on Tuesday
      if (now.weekday == DateTime.tuesday && now.hour == 0 && now.minute == 0) {
        // It's exactly 12:00 AM on Tuesday
        _disabledSkus.clear();
        prefs.remove(key); // Remove the key from shared preferences
        print("SKUs reset for a new week at 12:00 AM Tuesday.");
      } else if (now.isAfter(expirationDate)) {
        // If we are past the expiration date, do NOT clear the SKUs
        print("Current time is past expiration. SKUs are still valid.");
        List<String> skus = List<String>.from(storedData['skus']);
        setState(() {
          _disabledSkus = skus;
          print("Disabled SKUs loaded: $_disabledSkus");
        });
      } else {
        // SKUs are still valid
        List<String> skus = List<String>.from(storedData['skus']);
        setState(() {
          _disabledSkus = skus;
          print("Disabled SKUs loaded: $_disabledSkus");
        });
      }
    } catch (e) {
      print("Error loading disabled SKUs: $e");
      _disabledSkus.clear();
      prefs.remove(key); // Cleanup in case of error
    }
  }

  @override
  void initState() {
    super.initState();
    _inputid = generateInputID();

    // Load disabled SKUs after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDisabledSkus();
    });

    // Keep other listeners intact
    _beginningController.addListener(_calculateBeginning);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  void _calculateBeginning() {
    try {
      // Parse input values, default to 0 if empty
      int beginningSA = int.tryParse(_beginningSAController.text) ?? 0;
      int beginningWA = int.tryParse(_beginningWAController.text) ?? 0;

      // Calculate new beginning value
      int newBeginning = beginningSA + beginningWA;

      // Update the beginning controller with formatted integer value
      _beginningController.text = newBeginning.toString();
    } catch (e) {
      print('Error calculating beginning: $e');
      // Handle error appropriately (e.g., show an error message to the user)
    }
  }

  void _calculateEnding() {
    try {
      // Parse input values, default to 0 if empty
      int endingSA = int.tryParse(_endingSAController.text) ?? 0;
      int endingWA = int.tryParse(_endingWAController.text) ?? 0;

      // Calculate new beginning value
      int newEnding = endingSA + endingWA;

      // Update the beginning controller with formatted integer value
      _endingController.text = newEnding.toString();
    } catch (e) {
      print('Error calculating beginning: $e');
      // Handle error appropriately (e.g., show an error message to the user)
    }
  }

  void _calculateOfftake() {
    double beginning = double.tryParse(_beginningController.text) ?? 0;
    double delivery = double.tryParse(_deliveryController.text) ?? 0;
    double ending = double.tryParse(_endingController.text) ?? 0;
    double offtake = beginning + delivery - ending;
    _offtakeController.text = offtake.toStringAsFixed(2);
  }

  void _calculateInventoryDaysLevel() {
    double ending = double.tryParse(_endingController.text) ?? 0;
    double offtake = double.tryParse(_offtakeController.text) ?? 0;

    double inventoryDaysLevel = 0; // Default to 0

    if (offtake != 0 && ending != double.infinity && !ending.isNaN) {
      inventoryDaysLevel = ending / (offtake / 7);
    }

    if (inventoryDaysLevel.isNaN || inventoryDaysLevel.isInfinite) {
      inventoryDaysLevel = 0; // Assign 0 if the result is NaN or infinite
    }

    _inventoryDaysLevelController.text = inventoryDaysLevel == 0
        ? '' // Leave it empty if the value is 0
        : inventoryDaysLevel.toStringAsFixed(2);
  }

  void checkSaveEnabled() {
    setState(() {
      if (_statusSelected == 'Carried') {
        if (_selectedNumberOfDaysOOS == 0) {
          // Enable Save button when "0" is selected, but only if other fields are filled
          _isSaveEnabled = _endingController.text.isNotEmpty &&
              _deliveryController.text.isNotEmpty &&
              _beginningSAController.text.isNotEmpty &&
              _beginningWAController.text.isNotEmpty &&
              _endingSAController.text.isNotEmpty &&
              _endingWAController.text.isNotEmpty;
        } else {
          // Existing logic for when _selectedNumberOfDaysOOS is not 0
          _isSaveEnabled = _endingController.text.isNotEmpty &&
              _deliveryController.text.isNotEmpty &&
              _beginningSAController.text.isNotEmpty &&
              _beginningWAController.text.isNotEmpty &&
              _endingSAController.text.isNotEmpty &&
              _endingWAController.text.isNotEmpty;
          (_remarksOOS == "No P.O" ||
              _remarksOOS == "Unserved" ||
              (_remarksOOS == "No Delivery" &&
                  _selectedNoDeliveryOption != null));
        }
      } else {
        // Enable Save button for "Not Carried" and "Delisted" categories
        _isSaveEnabled = true;
      }
    });
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
    return WillPopScope(
        onWillPop: () async => false,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              appBar: AppBar(
                  backgroundColor: Colors.grey[600],
                  elevation: 0,
                  title: Text(
                    'Inventory Input',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
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
                              onPressed: _versionSelected == 'V1' ||
                                      _versionSelected == null
                                  ? () => _toggleDropdown('V1')
                                  : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    width: 2.0,
                                    color: _versionSelected == 'V1'
                                        ? Colors.grey
                                        : Colors.blueGrey.shade200),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Text(
                                'V1',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          SizedBox(
                              width:
                                  8), // Add spacing between buttons if needed
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _versionSelected == 'V2' ||
                                      _versionSelected == null
                                  ? () => _toggleDropdown('V2')
                                  : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    width: 2.0,
                                    color: _versionSelected == 'V2'
                                        ? Colors.grey
                                        : Colors.blueGrey.shade200),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Text(
                                'V2',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          SizedBox(
                              width:
                                  8), // Add spacing between buttons if needed
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _versionSelected == 'V3' ||
                                      _versionSelected == null
                                  ? () => _toggleDropdown('V3')
                                  : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    width: 2.0,
                                    color: _versionSelected == 'V3'
                                        ? Colors.grey
                                        : Colors.blueGrey.shade200),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Text(
                                'V3',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Add text fields where user input is expected, and assign controllers
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16, // Adjust as needed
                                ),
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              onChanged: (String? newValue) {
                                if (!_disabledSkus.contains(newValue)) {
                                  _selectSKU(newValue);
                                }
                              },
                              items:
                                  _categoryToSkuDescriptions[_versionSelected]!
                                      .map<DropdownMenuItem<String>>(
                                (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    enabled: !_disabledSkus.contains(
                                        value), // Disable if already selected for the branch
                                    child: Container(
                                      width: 315,
                                      child: Text(
                                        _disabledSkus.contains(value)
                                            ? "$value (DONE)"
                                            : value,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                        style: TextStyle(
                                          color: _disabledSkus.contains(value)
                                              ? Colors.red
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                              decoration: InputDecoration(
                                labelText:
                                    'Select SKU Description', // Label for the dropdown
                                border:
                                    OutlineInputBorder(), // Apply border to the TextField
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                            if (_productDetails != null) ...[
                              SizedBox(height: 10),
                              Text(
                                'Products',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              TextField(
                                controller:
                                    _productsController, // Assigning controller
                                readOnly: true,
                                decoration: InputDecoration(
                                  border:
                                      OutlineInputBorder(), // Apply border to the TextField
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal:
                                          12), // Padding inside the TextField
                                  hintText: _productDetails,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'SKU Code',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              TextField(
                                readOnly: true,
                                controller:
                                    _skuCodeController, // Assigning controller
                                decoration: InputDecoration(
                                  border:
                                      OutlineInputBorder(), // Apply border to the TextField
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal:
                                          12), // Padding inside the TextField
                                  hintText: _skuCode,
                                ),
                              ),
                            ],
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
                                        ? Colors.grey
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
                                        ? Colors.grey
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
                                        ? Colors.grey
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
                              onPressed: _addExpiryField,
                              style: OutlinedButton.styleFrom(
                                side:
                                    BorderSide(width: 2.0, color: Colors.grey),
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
                                  mainAxisAlignment: MainAxisAlignment
                                      .center, // Align rows to center
                                  children: [
                                    Expanded(child: _expiryFields[i]),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        _removeExpiryField(i);
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
                              _reasonOOS = null;

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
                          'Remarks',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          decoration: _statusSelected == 'Carried'
                              ? InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                )
                              : null, // No border or padding when status is not 'Carried'
                          value: _remarksOOS, // Ensure the value is not null
                          onChanged: (newValue) {
                            setState(() {
                              _remarksOOS = newValue;

                              // Show or hide the Select Reason dropdown based on the Remarks selection
                              if (_remarksOOS == 'No Delivery' &&
                                  _selectedNumberOfDaysOOS! > 0) {
                                _showNoDeliveryDropdown = true;
                              } else {
                                _showNoDeliveryDropdown = false;
                                _selectedNoDeliveryOption = null;
                                _reasonOOS = null;
                              }

                              // Check if Save button should be enabled
                              checkSaveEnabled();
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
                      ],
                      SizedBox(height: 10),
// Conditionally display the Reason dropdown if OOS days is greater than 0 and No Delivery is selected
                      if (_showNoDeliveryDropdown &&
                          _selectedNumberOfDaysOOS! > 0) ...[
                        Text(
                          'Reason',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          decoration: _statusSelected == 'Carried'
                              ? InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                )
                              : null, // No border or padding when status is not 'Carried'
                          value: _selectedNoDeliveryOption,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedNoDeliveryOption = newValue;
                              _reasonOOS =
                                  newValue; // Set the ReasonOOS value based on selection
                              checkSaveEnabled(); // Check if Save button should be enabled
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
                      SizedBox(height: 20),
                      if (_showCarriedTextField ||
                          _showNotCarriedTextField ||
                          _showDelistedTextField)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _isSaveEnabled
                                  ? () async {
                                      // Show confirmation dialog with preview
                                      bool confirmed = await showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Save Confirmation'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                      'Preview Inventory Item:'),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: 'Date: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                          text: DateFormat(
                                                                  'yyyy-MM-dd')
                                                              .format(DateTime
                                                                  .now()),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: 'Input ID: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text: _inputid),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: 'Name: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${widget.userName} ${widget.userLastName}',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'Account Name Branch ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text: widget
                                                                .selectedAccount),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: 'Period: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text: widget
                                                                .SelectedPeriod),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: 'Month: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text: widget
                                                                .selectedMonth),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: 'Week: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text: widget
                                                                .selectedWeek),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: 'Category: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text:
                                                                _versionSelected),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'SKU Description: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text:
                                                                _selectedDropdownValue),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: 'Products: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text:
                                                                _productDetails),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: 'SKU Code: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text: _skuCode),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: 'Status: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text:
                                                                _statusSelected),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'Beginning (Selling Area): ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${int.tryParse(_beginningSAController.text) ?? 0}',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'Beginning (Warehouse Area): ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${int.tryParse(_beginningWAController.text) ?? 0}',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'Ending (Selling Area): ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${int.tryParse(_endingSAController.text) ?? 0}',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'Ending (WAREHOUSE AREA): ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${int.tryParse(_endingWAController.text) ?? 0}',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'Beginning Value: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${int.tryParse(_beginningController.text) ?? 0}',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'Delivery Value: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${int.tryParse(_deliveryController.text) ?? 0}',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'Ending Value: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${int.tryParse(_endingController.text) ?? 0}',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'Offtake Value: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                          text: double.tryParse(
                                                                      _offtakeController
                                                                          .text)
                                                                  ?.toStringAsFixed(
                                                                      2) ??
                                                              '0.00',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'Inventory Days Level: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                          text: double.tryParse(
                                                                      _inventoryDaysLevelController
                                                                          .text)
                                                                  ?.toStringAsFixed(
                                                                      2) ??
                                                              '0.00',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'No of Days OOS: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text:
                                                                '$_selectedNumberOfDaysOOS'),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'Expiry Fields: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text:
                                                                '$_expiryFieldsValues'),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: 'Remarks OOS: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text:
                                                                '$_remarksOOS'),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: 'Reason OOS: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text:
                                                                '$_reasonOOS'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(
                                                      false); // Close dialog without saving
                                                },
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(
                                                      true); // Confirm saving
                                                },
                                                child: Text('Confirm'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirmed ?? false) {
                                        _saveInventoryItem(); // Call your save function here

                                        // Disable the selected SKU after saving the inventory item
                                        if (_selectedDropdownValue != null) {
                                          _saveSelectedSku(
                                              _selectedDropdownValue!);
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
                                        ); // Close the current screen after saving
                                      }
                                    }
                                  : null, // Disable button if !_isSaveEnabled
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all<
                                    EdgeInsetsGeometry>(
                                  const EdgeInsets.symmetric(vertical: 15),
                                ),
                                minimumSize: MaterialStateProperty.all<Size>(
                                  const Size(150, 50),
                                ),
                                backgroundColor: MaterialStateProperty.all<
                                        Color>(
                                    _isSaveEnabled ? Colors.grey : Colors.grey),
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
  final String? initialMonth; // Initial value for the dropdown
  final int? initialPcs; // Nullable initial value for the TextField

  ExpiryField({
    required this.index,
    required this.onExpiryFieldChanged,
    required this.onDeletePressed,
    this.initialMonth,
    this.initialPcs, // Make this nullable to allow an empty state
  });

  @override
  _ExpiryFieldState createState() => _ExpiryFieldState();
}

class _ExpiryFieldState extends State<ExpiryField> {
  String? _selectedMonth;
  final TextEditingController _expiryController = TextEditingController();
  bool _isMonthSelected = false; // New flag to track dropdown selection

  @override
  void initState() {
    super.initState();

    _selectedMonth = widget.initialMonth;
    if (widget.initialPcs != null) {
      _expiryController.text = widget.initialPcs.toString();
    }
    _expiryController.addListener(_onExpiryFieldChanged);
  }

  @override
  void dispose() {
    _expiryController.removeListener(_onExpiryFieldChanged);
    _expiryController.dispose();
    super.dispose();
  }

  void _onExpiryFieldChanged() {
    if (_isMonthSelected) {
      widget.onExpiryFieldChanged(
        _selectedMonth!,
        int.tryParse(_expiryController.text) ?? 0,
        widget.index,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(
          'Month of Expiry',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _selectedMonth,
          onChanged: (String? newValue) {
            setState(() {
              _selectedMonth = newValue;
              _isMonthSelected = newValue != null && newValue.isNotEmpty;
            });
            _onExpiryFieldChanged();
          },
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          hint: Text('Select Month'),
          items: [
            DropdownMenuItem<String>(
              value: '1 Month',
              child: Text('1 month'),
            ),
            DropdownMenuItem<String>(
              value: '2 Months',
              child: Text('2 months'),
            ),
            DropdownMenuItem<String>(
              value: '3 Months',
              child: Text('3 months'),
            ),
            DropdownMenuItem<String>(
              value: '4 Months',
              child: Text('4 months'),
            ),
            DropdownMenuItem<String>(
              value: '5 Months',
              child: Text('5 months'),
            ),
            DropdownMenuItem<String>(
              value: '6 Months',
              child: Text('6 months'),
            ),
          ],
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
              _isMonthSelected, // Enable TextField only when a month is selected
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

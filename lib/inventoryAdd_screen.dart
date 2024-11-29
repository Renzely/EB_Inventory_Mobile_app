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
      text: DateFormat('dd-MM-yyyy')
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
        DateTime(2024, 11, 18), // Week start
        DateTime(2024, 11, 24) // Week end (Sunday)
      ],
      [DateTime(2024, 11, 25), DateTime(2024, 12, 1)],
      [DateTime(2024, 12, 2), DateTime(2024, 12, 8)],
      [DateTime(2024, 12, 9), DateTime(2024, 12, 15)],
      [DateTime(2024, 12, 16), DateTime(2024, 12, 22)],
      [DateTime(2024, 12, 23), DateTime(2024, 12, 29)],
      [DateTime(2024, 12, 30), DateTime(2025, 1, 5)],
    ];

    List<DateTime> currentPeriod = periods.firstWhere(
        (period) =>
            currentDate.isAfter(period[0].subtract(const Duration(days: 1))) &&
            currentDate.isBefore(period[1].add(const Duration(days: 1))),
        orElse: () => [DateTime(0), DateTime(0)]);

    if (currentPeriod.isNotEmpty) {
      // Displayed workweek: Monday to Saturday
      String displayString =
          '${DateFormat('MMMdd').format(currentPeriod[0])}-${DateFormat('MMMdd').format(currentPeriod[1].subtract(Duration(days: 1)))}';

      // Covered week: Monday to Sunday
      String coveredString =
          '${DateFormat('MMMdd').format(currentPeriod[0])}-${DateFormat('MMMdd').format(currentPeriod[1])}';

      items.add(DropdownMenuItem(
          child: Text(displayString),
          value: coveredString // Store the full covered week as value
          ));

      print("Displayed week: $displayString");
      print("Covered week: $coveredString");
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
                backgroundColor: Color.fromARGB(255, 26, 20, 71),
                elevation: 0,
                title: Text(
                  'INVENTORY',
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
                              'DATE',
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
                              'MERCHANDISER',
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
                              'OUTLET',
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
                                'WEEKS COVERED',
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

                                                if (value != null) {
                                                  String actualValue = value
                                                          .split('-')[
                                                      0]; // Use the first date (start date)
                                                  print(
                                                      'Selected Period: $value');
                                                  switch (actualValue) {
                                                    case 'Nov18':
                                                      _monthController.text =
                                                          'November';
                                                      _weekController.text =
                                                          'Week 46';
                                                      break;
                                                    case 'Nov25':
                                                      _monthController.text =
                                                          'November';
                                                      _weekController.text =
                                                          'Week 47';
                                                      break;
                                                    case 'Dec02':
                                                      _monthController.text =
                                                          'November';
                                                      _weekController.text =
                                                          'Week 48';
                                                      break;
                                                    case 'Dec09':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 49';
                                                      break;
                                                    case 'Dec16':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 50';
                                                      break;
                                                    case 'Dec23':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 51';
                                                      break;
                                                    case 'Dec30':
                                                      _monthController.text =
                                                          'December';
                                                      _weekController.text =
                                                          'Week 52';
                                                      break;
                                                    default:
                                                      print(
                                                          'No match for selected period: $actualValue');
                                                      _monthController.clear();
                                                      _weekController.clear();
                                                      break;
                                                  }
                                                  _showAdditionalInfo =
                                                      true; // Ensure this is set to true
                                                } else {
                                                  _monthController.clear();
                                                  _weekController.clear();
                                                  _showAdditionalInfo =
                                                      false; // Reset if no period is selected
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
                                Text('MONTH',
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
                                SizedBox(height: 16),
                                Text(
                                  'WEEK',
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
                            SizedBox(height: 25),
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
                                        Color.fromARGB(255, 26, 20, 71),
                                      )),
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
        _dateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
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
  //String? _reasonOOS;
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
    //String reasonOOS = _reasonOOS ?? '';
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
      date: DateFormat('dd-MM-yyyy').format(DateTime.now()), // Current date
      inputId: inputid,
      name: '${widget.userName} ${widget.userLastName}',
      accountNameBranchManning: widget.selectedAccount,
      period: widget.SelectedPeriod,
      month: widget.selectedMonth,
      week: widget.selectedWeek,
      //category: Version,
      skuDescription: SKUDescription,
      //products: product,
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
      //reasonOOS: reasonOOS,
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
    //CATEGORY V1

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
      //_reasonOOS = null; // Reset Reason for OOS
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
        _skuCode = _skuToProductSkuCode[newValue]!['4-Pack Barcode'];
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
                  backgroundColor: Color.fromARGB(255, 26, 20, 71),
                  elevation: 0,
                  title: Text(
                    'INVENTORY',
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
                        'INVENTORY NUMBER',
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
                        'WEEK',
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
                        'MONTH',
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
                        'OUTLET',
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
                      // Text(
                      //   'Category',
                      //   style: TextStyle(
                      //       fontWeight: FontWeight.bold, fontSize: 16),
                      // ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _versionSelected == 'Variant' ||
                                      _versionSelected == null
                                  ? () => _toggleDropdown('Variant')
                                  : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    width: 2.0,
                                    color: _versionSelected == 'Variant'
                                        ? Color.fromARGB(255, 26, 20, 71)
                                        : Colors.blueGrey.shade200),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Text(
                                'VARIANT',
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
                                'SKUs',
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
                                // labelText:
                                //     'Select SKU Description', // Label for the dropdown
                                border:
                                    OutlineInputBorder(), // Apply border to the TextField
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                            if (_productDetails != null) ...[
                              SizedBox(height: 20),
                              Text(
                                '4-PACK BARCODE',
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
                          'BEGINNING (Selling Area)',
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
                          'BEGINNING (Warehouse Area)',
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
                          'ENDING (Selling Area)',
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
                          'ENDING (Warehouse Area)',
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
                          'TOTAL BEGINNING',
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
                          'DELIVERY',
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
                          'TOTAL ENDING',
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
                          'OFFTAKE',
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
                          'INVETORY DAYS LEVEL',
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
                                                                  'dd-MM-yyyy')
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
  final DateTime? initialDate; // Initial date value for the date picker
  final int? initialPcs; // Nullable initial value for the TextField

  ExpiryField({
    required this.index,
    required this.onExpiryFieldChanged,
    required this.onDeletePressed,
    this.initialDate,
    this.initialPcs, // Make this nullable to allow an empty state
  });

  @override
  _ExpiryFieldState createState() => _ExpiryFieldState();
}

class _ExpiryFieldState extends State<ExpiryField> {
  DateTime? _selectedDate;
  final TextEditingController _expiryController = TextEditingController();
  final DateFormat _dateFormat = DateFormat("ddMMMyy"); // Custom format
  bool _isDateSelected = false; // Flag to track if date is selected

  @override
  void initState() {
    super.initState();

    // Set initial date if provided
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _isDateSelected = true;
    }

    // Set initial pcs value if provided
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
    if (_isDateSelected) {
      widget.onExpiryFieldChanged(
        _dateFormat
            .format(_selectedDate!)
            .toUpperCase(), // Convert to uppercase
        int.tryParse(_expiryController.text) ?? 0,
        widget.index,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _isDateSelected = true;
      });
      _onExpiryFieldChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(
          'EXPIRY DATE',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 10),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Color.fromARGB(210, 46, 0, 77),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _selectedDate != null
                  ? _dateFormat
                      .format(_selectedDate!)
                      .toUpperCase() // Display formatted date in uppercase
                  : 'Select Expiry Date',
              style: TextStyle(
                color: _selectedDate != null ? Colors.black : Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'PCS of Expiry',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _expiryController,
          enabled: _isDateSelected, // Enable only when a date is selected
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

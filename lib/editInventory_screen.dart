// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, sort_child_properties_last

import 'package:bson/bson.dart';
import 'package:demo_app/dashboard_screen.dart';
import 'package:demo_app/dbHelper/constant.dart';
import 'package:demo_app/dbHelper/mongodbDraft.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:intl/intl.dart'; // Import for Random

class EditInventoryScreen extends StatefulWidget {
  final InventoryItem inventoryItem;
  final String userEmail;
  final String userName;
  final String userLastName;
  final String userMiddleName;
  final String userContactNum;
  final VoidCallback onCancel; // Add this line
  final VoidCallback onSave; // Declare the save callback

  const EditInventoryScreen({
    super.key,
    required this.inventoryItem,
    required this.userEmail,
    required this.userContactNum,
    required this.userLastName,
    required this.userMiddleName,
    required this.userName,
    required this.onCancel, // Add this line
    required this.onSave,
  });

  @override
  _EditInventoryScreenState createState() => _EditInventoryScreenState();
}

class _EditInventoryScreenState extends State<EditInventoryScreen> {
  late TextEditingController _dateController;
  late TextEditingController _inputIdController;
  late TextEditingController _nameController;
  late TextEditingController _branchController;
  late TextEditingController _periodController;
  late TextEditingController _weekController;
  late TextEditingController _monthController;
  // late TextEditingController _categoryController;
  late TextEditingController _skuDesController;
  //late TextEditingController _productController;
  late TextEditingController _skuCodeController;
  late TextEditingController _statusController;
  late TextEditingController _beginningController;
  late TextEditingController _deliveryController;
  late TextEditingController _endingController;
  late TextEditingController _endingSAController;
  late TextEditingController _endingWAController;
  late TextEditingController _offtakeController;
  late TextEditingController _IDLController;
  late TextEditingController _OOSController;
  late TextEditingController _remarksOOSController;
  late TextEditingController _reasonOOSController;

  final List<Widget> _expiryFields = [];
  final List<Map<String, dynamic>> _expiryFieldsValues = [];
  final List<String?> _selectedMonths = [];
  final List<TextEditingController> _pcsControllers = [];
  String? _selectedPeriod;
  bool _isSaveEnabled = false;
  int? _selectedNumberOfDaysOOS;
  String? _remarksOOS;
  bool _showNoDeliveryDropdown = false;
  String? _selectedNoDeliveryOption;
  String? selectedMonth;
  String currentStatus = ''; // Variable to hold the current status
  bool editing = false;
  List<DropdownMenuItem<String>> _periodItems = [];
  final DateTime _currentWeekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updatePeriodItems();

    _endingSAController = TextEditingController();
    _endingWAController = TextEditingController();

    int endingSA = int.tryParse(_endingSAController.text) ?? 0;
    int endingWA = int.tryParse(_endingWAController.text) ?? 0;

    int newEnding = endingSA + endingWA;

    // Set the current date and generate a new Input ID
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String newInputId = generateInputID();

    _dateController = TextEditingController(text: todayDate);
    _inputIdController = TextEditingController(text: newInputId);
    _nameController =
        TextEditingController(text: widget.inventoryItem.name ?? '');
    _branchController = TextEditingController(
        text: widget.inventoryItem.accountNameBranchManning ?? '');

    // Set "Month" and "Week" fields to be empty initially
    _periodController = TextEditingController(text: '');
    _weekController = TextEditingController(text: '');
    _monthController = TextEditingController(text: '');

    // _categoryController =
    //     TextEditingController(text: widget.inventoryItem.category ?? '');
    _skuDesController =
        TextEditingController(text: widget.inventoryItem.skuDescription ?? '');
    // _productController =
    //     TextEditingController(text: widget.inventoryItem.products ?? '');
    _skuCodeController =
        TextEditingController(text: widget.inventoryItem.skuCode ?? '');
    _statusController =
        TextEditingController(text: widget.inventoryItem.status ?? '');

    // Initialize with beginning value and attach listeners for calculations
    _beginningController = TextEditingController(
        text: widget.inventoryItem.ending?.toString() ?? '');
    _deliveryController = TextEditingController(text: '');
    _endingController = TextEditingController(text: '');
    _offtakeController = TextEditingController(text: '');
    _IDLController = TextEditingController(text: '0');

    // Set "No. of Days OOS", "Remarks OOS", and "Reason OOS" fields to be empty initially
    _OOSController = TextEditingController(text: '');
    _remarksOOSController = TextEditingController(text: '');
    _reasonOOSController = TextEditingController(text: '');

    // Attach listeners to calculate offtake and inventory days level
    _beginningController.addListener(_calculateOfftake);
    _deliveryController.addListener(_calculateOfftake);
    _endingController.addListener(_calculateOfftake);
    _offtakeController.addListener(_calculateInventoryDaysLevel);
    _endingController.addListener(_calculateEnding);

    _statusController.addListener(() {
      checkSaveEnabled();
    });

    _beginningController.addListener(() {
      checkSaveEnabled();
    });

    // _expiryFieldControllers = widget.inventoryItem.expiryFields.map((expiry) {
    //   return TextEditingController(text: expiry['expiryMonth'] ?? '');
    // }).toList();

    // Set initial values for the new fields
    _selectedNumberOfDaysOOS = null; // Initially set to null
    _remarksOOS = null; // Initially set to null
    _selectedNoDeliveryOption = null; // Initially set to null
    _showNoDeliveryDropdown = false; // Hide dropdown initially

    checkSaveEnabled();
  }

  void _calculateEnding() {
    try {
      // Parse input values, default to 0 if empty
      int endingSA = int.tryParse(_endingSAController.text) ?? 0;
      int endingWA = int.tryParse(_endingWAController.text) ?? 0;

      // Calculate new ending value
      int newEnding = endingSA + endingWA;

      // Update the ending controller with the total
      _endingController.text = newEnding.toString();
    } catch (e) {
      print('Error calculating ending: $e');
      // Handle error appropriately (e.g., show an error message to the user)
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _dateController.dispose();
    _inputIdController.dispose();
    _nameController.dispose();
    _branchController.dispose();
    _periodController.dispose();
    _weekController.dispose();
    _monthController.dispose();
    //_categoryController.dispose();
    _skuDesController.dispose();
    //_productController.dispose();
    _skuCodeController.dispose();
    _statusController.dispose();
    _beginningController.dispose();
    _deliveryController.dispose();
    _endingController.dispose();
    _endingSAController.dispose();
    _endingWAController.dispose();
    _offtakeController.dispose();
    _IDLController.dispose();
    _OOSController.dispose();
    _remarksOOSController.dispose();
    _reasonOOSController.dispose();

    for (var controller in _pcsControllers) {
      controller.dispose();
    }

    super.dispose();
  }

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
        DateTime(2024, 10, 20)
      ], // Actual range: Oct 12 - Oct 20 (labeled as Oct 12 - Oct 18)
      [
        DateTime(2024, 10, 19),
        DateTime(2024, 10, 27)
      ], // Actual range: Oct 19 - Oct 27 (labeled as Oct 19 - Oct 25)
      [
        DateTime(2024, 10, 26),
        DateTime(2024, 11, 3)
      ], // Actual range: Oct 26 - Nov 3 (labeled as Oct 26 - Nov 1)
      [
        DateTime(2024, 11, 2),
        DateTime(2024, 11, 10)
      ], // Actual range: Nov 2 - Nov 10 (labeled as Nov 2 - Nov 8)
      [
        DateTime(2024, 11, 9),
        DateTime(2024, 11, 17)
      ], // Actual range: Nov 9 - Nov 17 (labeled as Nov 9 - Nov 15)
      [
        DateTime(2024, 11, 16),
        DateTime(2024, 11, 24)
      ], // Actual range: Nov 16 - Nov 24 (labeled as Nov 16 - Nov 22)
      [
        DateTime(2024, 11, 23),
        DateTime(2024, 12, 1)
      ], // Actual range: Nov 23 - Dec 1 (labeled as Nov 23 - Nov 29)
      [
        DateTime(2024, 11, 30),
        DateTime(2024, 12, 8)
      ], // Actual range: Nov 30 - Dec 8 (labeled as Nov 30 - Dec 6)
      [
        DateTime(2024, 12, 7),
        DateTime(2024, 12, 15)
      ], // Actual range: Dec 7 - Dec 15 (labeled as Dec 7 - Dec 13)
      [
        DateTime(2024, 12, 14),
        DateTime(2024, 12, 22)
      ], // Actual range: Dec 14 - Dec 22 (labeled as Dec 14 - Dec 20)
      [
        DateTime(2024, 12, 21),
        DateTime(2024, 12, 29)
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
          '${DateFormat('MMMdd').format(currentPeriod[0])}-${DateFormat('MMMdd').format(currentPeriod[1].subtract(Duration(days: 2)))}';
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

  // Function to generate a new Input ID
  String generateInputID() {
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    var random =
        Random().nextInt(10000); // Generate a random number between 0 and 9999
    var paddedRandom =
        random.toString().padLeft(4, '0'); // Ensure it has 4 digits
    return '2000$paddedRandom';
  }

  // Method to calculate offtake
  void _calculateOfftake() {
    double beginning = double.tryParse(_beginningController.text) ?? 0;
    double delivery = double.tryParse(_deliveryController.text) ?? 0;
    double ending = double.tryParse(_endingController.text) ?? 0;
    double offtake = beginning + delivery - ending;

    setState(() {
      _offtakeController.text = offtake.toStringAsFixed(2);
    });

    _calculateInventoryDaysLevel(); // Recalculate inventory days level when offtake changes
  }

  // Method to calculate inventory days level
  void _calculateInventoryDaysLevel() {
    double ending = double.tryParse(_endingController.text) ?? 0;
    double offtake = double.tryParse(_offtakeController.text) ?? 0;

    if (offtake != 0) {
      double inventoryDaysLevel = ending / (offtake / 7);

      setState(() {
        _IDLController.text = inventoryDaysLevel.toStringAsFixed(2);
      });
    } else {
      setState(() {
        _IDLController.text = '0';
      });
    }
  }

  void checkSaveEnabled() {
    setState(() {
      if (_statusController.text == 'Carried') {
        // Restore the original value of _beginningController if status changes from 'Delisted'
        if (_beginningController.text == 'Delisted') {
          _beginningController.text =
              widget.inventoryItem.ending?.toString() ?? '';
        }

        // Enable Save button when _selectedNumberOfDaysOOS is 0, ensuring selectedPeriod and delivery fields are filled
        if (_selectedNumberOfDaysOOS == 0) {
          _isSaveEnabled =
              _selectedPeriod != null && // Ensure _selectedPeriod is not null
                  _deliveryController.text
                      .isNotEmpty && // Ensure deliveryController is not empty
                  _endingController
                      .text.isNotEmpty; // Ensure endingController is not empty
        } else {
          // When _selectedNumberOfDaysOOS is not 0, enable Save button if all required fields are filled and valid
          _isSaveEnabled = _beginningController.text.isNotEmpty &&
              _deliveryController.text.isNotEmpty &&
              _endingController.text.isNotEmpty &&
              _endingSAController.text.isNotEmpty &&
              _endingWAController.text.isNotEmpty &&
              _selectedPeriod != null && // Ensure _selectedPeriod is not null
              _remarksOOS != null && // Ensure remarksOOS is not null
              (_remarksOOS == "No P.O" ||
                  _remarksOOS == "Unserved" ||
                  (_remarksOOS == "No Delivery" &&
                      _selectedNoDeliveryOption != null));
        }
      } else if (_statusController.text == 'Delisted') {
        // If status is 'Delisted', set beginning to 'Delisted'
        _beginningController.text = 'Delisted';

        // Enable Save button without requiring all fields, as they may not apply
        _isSaveEnabled = true;
      }
    });
  }

  void _saveChanges() async {
    mongo.Db? db;

    try {
      // Initialize the connection to the MongoDB database
      db = await mongo.Db.create(MONGO_CONN_URL);
      await db.open();

      // Reference the correct collection
      final collection = db.collection(USER_INVENTORY);

      // Prepare the data for insertion
      String endingSA = _endingSAController.text;
      String endingWA = _endingWAController.text;
      String accountManning = _branchController.text;
      String status = _statusController.text;
      int beginning = int.tryParse(_beginningController.text) ?? 0;
      String beginningvalue = _beginningController.text;
      String deliveryValue;
      String endingValue;
      String offtakevalue = '0.00';
      double inventoryDaysLevel = 0;
      String noOfDaysOOSValue = '0';
      String remarksOOSValue = '';
      String reasonOOSValue = '';

      if (status == 'Delisted') {
        beginningvalue = 'Delisted';
        deliveryValue = 'Delisted';
        endingValue = 'Delisted';
        endingWA = 'Delisted';
        endingSA = 'Delisted';
        remarksOOSValue = 'Delisted';
        reasonOOSValue = 'Delisted';
      } else {
        deliveryValue =
            int.tryParse(_deliveryController.text)?.toString() ?? '0';
        endingValue = int.tryParse(_endingController.text)?.toString() ?? '0';
        offtakevalue = int.tryParse(_offtakeController.text)?.toString() ?? '0';
      }

      // Calculate offtake
      int beginningValue = beginning;
      int delivery = int.tryParse(_deliveryController.text) ?? 0;
      int ending = int.tryParse(_endingController.text) ?? 0;
      int offtake = beginningValue + delivery - ending;

      if (status != 'Delisted') {
        if (offtake != 0 && ending != double.infinity && !ending.isNaN) {
          inventoryDaysLevel = ending / (offtake / 7);
        }
      }

      List<Map<String, String>> expiryFieldsData = []; // Explicitly define type
      int maxIndex = max(_selectedMonths.length, _pcsControllers.length);

      for (int i = 0; i < maxIndex; i++) {
        String expiryMonth =
            i < _selectedMonths.length ? _selectedMonths[i] ?? '' : '';
        String expiryPcs =
            i < _pcsControllers.length ? _pcsControllers[i].text : '';

        if (expiryMonth.isNotEmpty || expiryPcs.isNotEmpty) {
          expiryFieldsData.add({
            'expiryMonth': expiryMonth,
            'expiryPcs': expiryPcs,
          });
          print("Added expiry field: ${expiryFieldsData.last}");
        } else {
          print("Skipping empty field at index $i");
        }
      }

      // Prepare the document to insert
      var newDocument = {
        'userEmail': widget.userEmail,
        'date': _dateController.text,
        'inputId': _inputIdController.text,
        'name': _nameController.text,
        'accountNameBranchManning': accountManning,
        'period': _selectedPeriod,
        'month': _monthController.text,
        'week': _weekController.text,
        //'category': _categoryController.text,
        'skuDescription': _skuDesController.text,
        //'products': _productController.text,
        'skuCode': _skuCodeController.text,
        'status': status,
        'beginning': beginningValue.toString(),
        'delivery': deliveryValue,
        'ending': endingValue,
        'endingSA': endingSA,
        'endingWA': endingWA,
        'offtake': offtake.toString(),
        'inventoryDaysLevel': inventoryDaysLevel,
        'noOfDaysOOS': noOfDaysOOSValue,
        'expiryFields': expiryFieldsData,
        'remarksOOS': remarksOOSValue,
        'reasonOOS': reasonOOSValue,
        'isEditing': false, // Add the editing status here
      };

      // Log the final document before insertion
      print('Final Document to Insert: $newDocument');

      // Insert the new document into the collection
      await collection.insertOne(newDocument);
      print('New inventory item inserted successfully.');

      // Check if the widget is still mounted before navigating
      if (mounted) {
        Navigator.pop(context, true); // Indicate that editing is done
      }
    } catch (e) {
      print('Error inserting new inventory item: $e');
      // Check if the widget is still mounted before navigating
      if (mounted) {
        Navigator.pop(context,
            false); // Indicate that editing is not done if there's an error
      }
    } finally {
      // Ensure the database connection is closed if it was opened
      if (db != null) {
        await db.close();
      }
    }
  }

  bool _isFieldsEnabled() {
    return _statusController.text == 'Carried';
  }

  void _resetFields() {
    _deliveryController.clear();
    _endingController.clear();
    _offtakeController.clear();
    _endingSAController.clear();
    _endingWAController.clear();
    // _selectedPeriod = null;
    // _monthController.clear();
    // _weekController.clear();
    _IDLController.clear();
    _expiryFields.clear();
    _pcsControllers.clear();
    _selectedMonths.clear();
    _selectedNumberOfDaysOOS = null;
    _remarksOOS = null;
    _selectedNoDeliveryOption = null;
    _showNoDeliveryDropdown = false;
  }

  void _addExpiryField() {
    if (currentStatus != 'Delisted') {
      setState(() {
        if (_expiryFields.length < 6) {
          int index = _expiryFields.length;
          _pcsControllers.add(TextEditingController()); // Add a new controller
          _selectedMonths.add(null); // Add a null entry for the new field
          _expiryFields.add(_buildExpiryField(index));
          _expiryFieldsValues.add({'expiryMonth': '', 'expiryPcs': ''});
        }
      });
    } else {
      // Optionally, show a message to the user that expiry fields cannot be added for delisted or not carried items
      print('Cannot add expiry fields for delisted or not carried items');
    }
  }

  void _removeExpiryField(int index) {
    setState(() {
      _expiryFields.removeAt(index);
      _expiryFieldsValues.removeAt(index);
      _selectedMonths
          .removeAt(index); // Remove the corresponding selected month
      _pcsControllers.removeAt(index); // Remove the corresponding controller

      // Update the index of remaining fields
      for (int i = 0; i < _expiryFields.length; i++) {
        _expiryFields[i] = _buildExpiryField(i);
      }
    });
  }

  void _updateExpiryField(int index, String expiryMonth, String expiryPcs) {
    setState(() {
      _expiryFieldsValues[index] = {
        'expiryMonth': expiryMonth,
        'expiryPcs': expiryPcs,
      };
    });
  }

  void _resetExpiryFields() {
    _expiryFields.clear();
    _pcsControllers.clear();
    _selectedMonths.clear();
  }

  void _updateStatus(String status) {
    setState(() {
      currentStatus = status;
      if (status == 'Delisted') {
        _resetExpiryFields(); // Clear existing expiry fields if the status changes to delisted or not carried
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Color.fromARGB(210, 46, 0, 77),
              elevation: 0,
              title: Text(
                'Next Week Inventory',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            body: SingleChildScrollView(
                child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      readOnly: true,
                      controller: _dateController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Input ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      readOnly: true,
                      controller: _inputIdController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Merchandiser',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      readOnly: true,
                      controller: _nameController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      enabled: false,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Branch/Outlet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _branchController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      enabled: false,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Weeks Covered',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPeriod = value;
                                      _isSaveEnabled = _selectedPeriod != null;
                                      if (value != null) {
                                        String actualValue =
                                            value.split('-')[1];
                                        print('Selected period: $value');
                                        switch (actualValue) {
                                          case 'Oct18':
                                            _monthController.text = 'October';
                                            _weekController.text = 'Week 42';
                                            break;
                                          case 'Oct25':
                                            _monthController.text = 'October';
                                            _weekController.text = 'Week 43';
                                            break;
                                          case 'Nov01':
                                            _monthController.text = 'November';
                                            _weekController.text = 'Week 44';
                                            break;
                                          case 'Nov08':
                                            _monthController.text = 'November';
                                            _weekController.text = 'Week 45';
                                            break;
                                          case 'Nov15':
                                            _monthController.text = 'November';
                                            _weekController.text = 'Week 46';
                                            break;
                                          case 'Nov22':
                                            _monthController.text = 'November';
                                            _weekController.text = 'Week 47';
                                            break;
                                          case 'Nov29':
                                            _monthController.text = 'November';
                                            _weekController.text = 'Week 48';
                                            break;
                                          case 'Dec06':
                                            _monthController.text = 'December';
                                            _weekController.text = 'Week 49';
                                            break;
                                          case 'Dec13':
                                            _monthController.text = 'December';
                                            _weekController.text = 'Week 50';
                                            break;
                                          case 'Dec20':
                                            _monthController.text = 'December';
                                            _weekController.text = 'Week 51';
                                            break;
                                          case 'Dec27':
                                            _monthController.text = 'December';
                                            _weekController.text = 'Week 52';
                                            break;
                                          default:
                                            _monthController.clear();
                                            _weekController.clear();
                                            break;
                                        }
                                        checkSaveEnabled(); // Ensure button state is updated
                                      }
                                    });
                                  },
                                  items: _periodItems,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                                if (_selectedPeriod != null)
                                  Positioned(
                                    right: 0,
                                    child: IconButton(
                                      icon: Icon(Icons.arrow_drop_down),
                                      onPressed: () {
                                        // Dropdown button action
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16), // Adjust spacing as needed
                    Text(
                      'Month',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _monthController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      readOnly:
                          true, // Keep readOnly to prevent direct user input
                    ),
                    SizedBox(height: 16), // Adjust spacing as needed
                    Text(
                      'Week',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _weekController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      readOnly:
                          true, // Keep readOnly to prevent direct user input
                    ),
                    //SizedBox(height: 16),
                    // Text(
                    //   'Category',
                    //   style: TextStyle(
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: 16,
                    //   ),
                    // ),
                    // SizedBox(height: 16),
                    // TextField(
                    //   controller: _categoryController,
                    //   decoration: InputDecoration(
                    //       border: OutlineInputBorder(),
                    //       contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    //   enabled: false,
                    // ),
                    SizedBox(height: 16),
                    Text(
                      'SKU Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _skuDesController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      enabled: false,
                    ),
                    // SizedBox(height: 16),
                    // Text(
                    //   'Product',
                    //   style: TextStyle(
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: 16,
                    //   ),
                    // ),
                    // SizedBox(height: 16),
                    // TextField(
                    //   controller: _productController,
                    //   decoration: InputDecoration(
                    //       border: OutlineInputBorder(),
                    //       contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    //   enabled: false,
                    // ),
                    SizedBox(height: 16),
                    Text(
                      'SKU Code',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _skuCodeController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      enabled: false,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _statusController.text,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: <String>['Carried', 'Delisted']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _statusController.text = newValue!;

                          if (newValue == 'Delisted') {
                            _resetFields();
                          }
                        });
                      },
                    ),

                    SizedBox(height: 16),
                    Text(
                      'Beginning',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _beginningController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      keyboardType: TextInputType.number,
                      readOnly: true,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Delivery',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _deliveryController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      keyboardType: TextInputType.number,
                      enabled:
                          _isFieldsEnabled(), // Enable or disable based on status
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Ending (Selling Area)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _endingSAController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: _isFieldsEnabled(),
                      onChanged: (_) =>
                          _calculateEnding(), // Call calculate on change
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Ending (Warehouse Area)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _endingWAController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: _isFieldsEnabled(),
                      onChanged: (_) =>
                          _calculateEnding(), // Call calculate on change
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Ending',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _endingController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: _isFieldsEnabled(),
                    ),
                    SizedBox(height: 20),
                    SizedBox(height: 20),
                    Text(
                      'Expiration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    Column(
                      children: _expiryFields
                          .map((field) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 30.0), // Adds space between fields
                                child: field,
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: OutlinedButton(
                        onPressed: _isFieldsEnabled()
                            ? _addExpiryField
                            : null, // Enable button if _isFieldsEnabled() is true, otherwise disable
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              width: 2.0,
                              color: _isFieldsEnabled()
                                  ? Color.fromARGB(210, 46, 0, 77)
                                  : Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          'Add Expiry',
                          style: TextStyle(
                            color: _isFieldsEnabled()
                                ? Colors.black
                                : Color.fromARGB(210, 46, 0,
                                    77), // Change text color when disabled
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),
                    Text(
                      'Offtake',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _offtakeController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      keyboardType: TextInputType.number,
                      readOnly: true,
                      enabled:
                          _isFieldsEnabled(), // Enable or disable based on status
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Inventory Days Level',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _IDLController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      keyboardType: TextInputType.number,
                      readOnly: true,
                      enabled:
                          _isFieldsEnabled(), // Enable or disable based on status
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No. of Days OOS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        enabled:
                            _isFieldsEnabled(), // Enable or disable based on status
                      ),
                      value: _selectedNumberOfDaysOOS,
                      onChanged: _isFieldsEnabled()
                          ? (newValue) {
                              setState(() {
                                _selectedNumberOfDaysOOS = newValue;
                                _remarksOOS = null; // Reset remarks and reason
                                _selectedNoDeliveryOption = null;
                                _showNoDeliveryDropdown =
                                    false; // Hide Reason dropdown initially
                                checkSaveEnabled(); // Check if Save button should be enabled
                              });
                            }
                          : null, // Disable dropdown if fields are not enabled
                      items: List.generate(8, (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(index.toString()),
                        );
                      }),
                    ),
                    SizedBox(height: 16),
                    if (_selectedNumberOfDaysOOS != null &&
                        _selectedNumberOfDaysOOS! > 0 &&
                        _isFieldsEnabled()) ...[
                      SizedBox(height: 10),
                      if (_selectedNumberOfDaysOOS != null &&
                          _selectedNumberOfDaysOOS! > 0) ...[
                        Text(
                          'Remarks',
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
                    ],
                    SizedBox(height: 16),
                    if (_showNoDeliveryDropdown && _isFieldsEnabled()) ...[],
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Perform cancel action
                            widget.onCancel(); // Call the onCancel callback
                            Navigator.of(context)
                                .pop(); // Just pop without pushing a new route
                          },
                          style: ButtonStyle(
                            padding:
                                MaterialStateProperty.all<EdgeInsetsGeometry>(
                              const EdgeInsets.symmetric(vertical: 15),
                            ),
                            minimumSize: MaterialStateProperty.all<Size>(
                              const Size(150, 50),
                            ),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Color.fromARGB(210, 46, 0, 77)),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _isSaveEnabled
                                  ? () async {
                                      // Show confirmation dialog before saving
                                      bool confirmed = await showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Save Confirmation'),
                                            content: Text(
                                                'Do you want to save the changes?'),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(
                                                      false); // Close dialog
                                                },
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(
                                                      true); // Confirm save
                                                },
                                                child: Text('Confirm'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      // If user confirmed, proceed to save
                                      if (confirmed ?? false) {
                                        _saveChanges(); // Call the save function
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Changes saved successfully'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        widget.onSave();
                                        Navigator.pop(
                                            context); // Navigate back if needed
                                      }
                                    }
                                  : null, // Disable button if save is not enabled
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
                                      ? Color.fromARGB(210, 46, 0, 77)
                                      : Colors.grey,
                                ),
                              ),
                              child: const Text(
                                'Save Changes',
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
                  ]),
            ))));
  }

  Widget _buildExpiryField(int index) {
    if (index >= _pcsControllers.length || index >= _selectedMonths.length) {
      return SizedBox
          .shrink(); // Return an empty widget if the index is out of bounds
    }

    TextEditingController pcsController = _pcsControllers[index];
    String? selectedMonth = _selectedMonths[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedMonth,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedMonth = newValue;
                    _selectedMonths[index] = selectedMonth!;
                    pcsController
                        .clear(); // Clear TextField when a new month is selected

                    // Only update if a month is selected
                    if (selectedMonth != null) {
                      _updateExpiryField(
                          index, selectedMonth!, pcsController.text);
                    }
                  });
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
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _removeExpiryField(index);
              },
            ),
          ],
        ),
        SizedBox(height: 16),
        TextField(
          controller: pcsController,
          decoration: InputDecoration(
            hintText: 'Manual PCS Input',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            // Only call _updateExpiryField if selectedMonth is not null
            if (selectedMonth != null) {
              _updateExpiryField(index, selectedMonth!, pcsController.text);
            } else {
              // Optionally, show a message or handle the case where no month is selected
              print('Please select a month before entering PCS.');
            }
          },
        ),
      ],
    );
  }
}

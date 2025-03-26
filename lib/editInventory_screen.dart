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
  final List<InventoryItem> inventoryItems;
  final String userEmail;
  final String userName;
  final String userLastName;
  final String userMiddleName;
  final String userContactNum;
  final VoidCallback onCancel; // Add this line
  final VoidCallback onSave; // Declare the save callback

  const EditInventoryScreen({
    Key? key,
    required this.inventoryItems,
    required this.userEmail,
    required this.userContactNum,
    required this.userLastName,
    required this.userMiddleName,
    required this.userName,
    required this.onCancel, // Add this line
    required this.onSave,
  }) : super(key: key);

  @override
  _EditInventoryScreenState createState() => _EditInventoryScreenState();
}

class _EditInventoryScreenState extends State<EditInventoryScreen> {
  List<TextEditingController> _dateControllers = [];
  List<TextEditingController> _inputIdControllers = [];
  List<TextEditingController> _nameControllers = [];
  List<TextEditingController> _branchControllers = [];
  List<TextEditingController> _periodControllers = [];
  List<TextEditingController> _weekControllers = [];
  List<TextEditingController> _monthControllers = [];
  List<TextEditingController> _skuDesControllers = [];
  List<TextEditingController> _skuCodeControllers = [];
  List<TextEditingController> _statusControllers = [];
  List<TextEditingController> _beginningControllers = [];
  List<TextEditingController> _deliveryControllers = [];
  List<TextEditingController> _endingControllers = [];
  List<TextEditingController> _endingSAControllers = [];
  List<TextEditingController> _endingWAControllers = [];
  List<TextEditingController> _offtakeControllers = [];
  List<TextEditingController> _IDLControllers = [];
  List<TextEditingController> _OOSControllers = [];
  List<TextEditingController> _remarksOOSControllers = [];

  List<int?> _selectedNumberOfDaysOOSList = [];
  List<String?> _remarksOOSList = [];

  List<TextEditingController> _pcsControllers = [];
  List<String?> _selectedMonths = [];
  List<Widget> _expiryFields = [];
  List<bool> _isSaveEnabledList = [];
  List<String?> _originalBeginningValues = [];
  List<Map<String, String>> _expiryFieldsValues = [];
  String? _selectedPeriod;
  bool _isSaveEnabled = false;
  int? _selectedNumberOfDaysOOS;
  String? _remarksOOS;

  String? _selectedNoDeliveryOption;
  String? selectedMonth;
  String currentStatus = ''; // Variable to hold the current status
  bool editing = false;
  List<DropdownMenuItem<String>> _periodItems = [];
  DateTime _currentWeekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updatePeriodItems();

    int itemCount = widget.inventoryItems.length;

    _selectedNumberOfDaysOOSList = List.generate(itemCount, (index) => null);
    _isSaveEnabledList = List.filled(itemCount, false);
    _originalBeginningValues =
        List.filled(itemCount, null); // Ensure initialization

    print("widget.inventoryItems length: $itemCount");
    print(
        "_selectedNumberOfDaysOOSList initialized with length: ${_selectedNumberOfDaysOOSList.length}");
    print(
        "_isSaveEnabledList initialized with length: ${_isSaveEnabledList.length}");

    initializeLists(itemCount);
    updateListsIfNeeded(itemCount);

    for (var i = 0; i < itemCount; i++) {
      var item = widget.inventoryItems[i];

      _dateControllers.add(TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(DateTime.now())));
      _inputIdControllers.add(TextEditingController(text: generateInputID()));
      _nameControllers.add(TextEditingController(text: item.name ?? ''));
      _branchControllers.add(
          TextEditingController(text: item.accountNameBranchManning ?? ''));
      _periodControllers.add(TextEditingController(text: ''));
      _weekControllers.add(TextEditingController(text: ''));
      _monthControllers.add(TextEditingController(text: ''));
      // _categoryControllers
      //     .add(TextEditingController(text: item.category ?? ''));
      _skuDesControllers
          .add(TextEditingController(text: item.skuDescription ?? ''));
      _skuCodeControllers.add(TextEditingController(text: item.skuCode ?? ''));
      _statusControllers.add(TextEditingController(text: item.status ?? ''));
      _beginningControllers
          .add(TextEditingController(text: item.ending?.toString() ?? ''));
      _deliveryControllers.add(TextEditingController(text: ''));

      _endingSAControllers.add(TextEditingController());
      _endingWAControllers.add(TextEditingController());
      _endingControllers.add(TextEditingController());

      _offtakeControllers.add(TextEditingController(text: ''));
      _IDLControllers.add(TextEditingController(text: '0'));
      _OOSControllers.add(TextEditingController(text: ''));
      _remarksOOSControllers.add(TextEditingController(text: ''));

      _endingSAControllers[i].addListener(() => _calculateEnding(i));
      _endingWAControllers[i].addListener(() => _calculateEnding(i));

      _beginningControllers[i].addListener(() => _calculateOfftake(i));
      _deliveryControllers[i].addListener(() => _calculateOfftake(i));
      _endingControllers[i].addListener(() => _calculateOfftake(i));
      _offtakeControllers[i].addListener(() => _calculateInventoryDaysLevel(i));
    }
  }

  void updateListsIfNeeded(int length) {
    if (_remarksOOSList.length < length) {
      _remarksOOSList
          .addAll(List.generate(length - _remarksOOSList.length, (_) => null));
    }
  }

  void initializeLists(int length) {
    _remarksOOSList = List.generate(length, (_) => null);
  }

  void _calculateEnding(int index) {
    try {
      int endingSA = int.tryParse(_endingSAControllers[index].text) ?? 0;
      int endingWA = int.tryParse(_endingWAControllers[index].text) ?? 0;
      int newEnding = endingSA + endingWA;

      setState(() {
        _endingControllers[index].text = newEnding.toString();
      });
    } catch (e) {
      print('Error calculating ending for inventory #${index + 1}: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in [
      ..._dateControllers,
      ..._inputIdControllers,
      ..._nameControllers,
      ..._branchControllers,
      ..._periodControllers,
      ..._weekControllers,
      ..._monthControllers,
      ..._skuDesControllers,
      ..._skuCodeControllers,
      ..._statusControllers,
      ..._beginningControllers,
      ..._deliveryControllers,
      ..._endingControllers,
      ..._endingSAControllers,
      ..._endingWAControllers,
      ..._offtakeControllers,
      ..._IDLControllers,
      ..._OOSControllers,
      ..._remarksOOSControllers,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

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

//  List<List<DateTime>> _generatePeriods(DateTime startDate) {
//     List<List<DateTime>> periods = [];

//     // Generate 5 periods (Monday to Saturday)
//     for (int i = 0; i < 5; i++) {
//       DateTime periodStart =
//           startDate.add(Duration(days: i * 7)); // Start of each week (Monday)
//       DateTime periodEnd =
//           periodStart.add(Duration(days: 5)); // End of each week (Saturday)
//       periods.add([periodStart, periodEnd]);
//     }

//     return periods;
//   }

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
  void _calculateOfftake(int index) {
    double beginning = double.tryParse(_beginningControllers[index].text) ?? 0;
    double delivery = double.tryParse(_deliveryControllers[index].text) ?? 0;
    double ending = double.tryParse(_endingControllers[index].text) ?? 0;
    double offtake = beginning + delivery - ending;

    setState(() {
      _offtakeControllers[index].text = offtake.toStringAsFixed(2);
    });

    _calculateInventoryDaysLevel(
        index); // Recalculate inventory days level when offtake changes
  }

  // Method to calculate inventory days level
  void _calculateInventoryDaysLevel(int index) {
    double ending = double.tryParse(_endingControllers[index].text) ?? 0;
    double offtake = double.tryParse(_offtakeControllers[index].text) ?? 0;

    if (offtake != 0) {
      double inventoryDaysLevel = ending / (offtake / 7);

      setState(() {
        _IDLControllers[index].text = inventoryDaysLevel.toStringAsFixed(2);
      });
    } else {
      setState(() {
        _IDLControllers[index].text = '0';
      });
    }
  }

  void checkSaveEnabled(int index) {
    setState(() {
      print("Checking index: $index");
      print("_statusControllers length: ${_statusControllers.length}");
      print(
          "_selectedNumberOfDaysOOSList length: ${_selectedNumberOfDaysOOSList.length}");
      print("_isSaveEnabledList length: ${_isSaveEnabledList.length}");

      // Ensure index is within bounds
      if (index >= _statusControllers.length ||
          index >= _selectedNumberOfDaysOOSList.length ||
          index >= _isSaveEnabledList.length) {
        print("Index out of range, skipping checkSaveEnabled");
        return;
      }

      if (_statusControllers[index].text == 'Carried') {
        if (_selectedNumberOfDaysOOSList[index] == 0) {
          _remarksOOSList[index] = null;

          _isSaveEnabledList[index] = _selectedPeriod != null &&
              _deliveryControllers[index].text.isNotEmpty &&
              _endingControllers[index].text.isNotEmpty;
        } else {
          _isSaveEnabledList[index] =
              _beginningControllers[index].text.isNotEmpty &&
                  _deliveryControllers[index].text.isNotEmpty &&
                  _endingControllers[index].text.isNotEmpty &&
                  _selectedPeriod != null &&
                  _remarksOOSList[index] != null;
        }
      } else if (_statusControllers[index].text == 'Delisted') {
        // Do NOT overwrite the beginning value
        // We DO NOT change the _beginningControllers[index].text here

        // Enable save only if a period is selected
        _isSaveEnabledList[index] = _selectedPeriod != null;
      } else {
        _isSaveEnabledList[index] = false;
      }

      // Debugging output
      print('_isSaveEnabledList: $_isSaveEnabledList');

      // Update save button state
      _isSaveEnabled = _isSaveEnabledList.every((enabled) {
        int i = _isSaveEnabledList.indexOf(enabled);
        if (_statusControllers[i].text == "Delisted") {
          return _selectedPeriod != null; // Require period for 'Delisted' items
        }
        return enabled; // Only enable if valid
      });
    });
  }

  Widget _buildExpiryField(int index) {
    if (index >= _pcsControllers.length || index >= _selectedMonths.length) {
      return SizedBox.shrink(); // Prevent crash if index is out of range
    }

    TextEditingController pcsController = _pcsControllers[index];

    // Use a controller for the date field to update it dynamically
    TextEditingController dateController = TextEditingController(
      text: _selectedMonths[index] ?? '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                readOnly: true, // Prevent manual input
                controller: dateController, // Use controller for updates
                decoration: InputDecoration(
                  hintText: 'Select Expiry Date',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  suffixIcon: Icon(Icons.calendar_today), // Calendar icon
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now()
                        .add(Duration(days: 365 * 5)), // Up to 5 years ahead
                  );

                  if (pickedDate != null) {
                    setState(() {
                      String formattedDate = _formatDate(pickedDate);
                      _selectedMonths[index] = formattedDate;
                      dateController.text = formattedDate; // Update text field
                      _updateExpiryField(
                          index, formattedDate, pcsController.text);
                    });
                  }
                },
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
            _updateExpiryField(index, _selectedMonths[index] ?? '', value);
          },
        ),
      ],
    );
  }

// Helper function to format the date as ddMMMyy
  String _formatDate(DateTime date) {
    String day = date.day.toString().padLeft(2, '0'); // Ensure two-digit day
    String month = _monthToAbbreviation(date.month);
    String year =
        date.year.toString().substring(2); // Get last two digits of the year
    return '$day$month$year';
  }

// Convert numeric month to three-letter abbreviation
  String _monthToAbbreviation(int month) {
    List<String> months = [
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MAY",
      "JUN",
      "JUL",
      "AUG",
      "SEP",
      "OCT",
      "NOV",
      "DEC"
    ];
    return months[month - 1]; // Get corresponding month abbreviation
  }

  void _saveChanges() async {
    mongo.Db? db;

    try {
      // Initialize the connection to the MongoDB database
      db = await mongo.Db.create(MONGO_CONN_URL);
      await db.open();

      // Reference the correct collection
      final collection = db.collection(USER_INVENTORY);

      // Loop through each inventory item and save its data
      for (int i = 0; i < widget.inventoryItems.length; i++) {
        // Prepare the data for insertion
        String endingSA = _endingSAControllers[i].text;
        String endingWA = _endingWAControllers[i].text;
        String accountManning = _branchControllers[i].text;
        String status = _statusControllers[i].text;
        //int beginning = int.tryParse(_beginningControllers[i].text) ?? 0;
        String beginningValue = _beginningControllers[i].text;
        String deliveryValue;
        String endingValue;
        String offtakeValue = _offtakeControllers[i].text.isNotEmpty
            ? _offtakeControllers[i].text
            : '0.00';
        double inventoryDaysLevel = 0;
        String noOfDaysOOSValue = _selectedNumberOfDaysOOSList.isNotEmpty &&
                i < _selectedNumberOfDaysOOSList.length &&
                _selectedNumberOfDaysOOSList[i] != null
            ? _selectedNumberOfDaysOOSList[i].toString()
            : '0';
        String remarksOOSValue = _remarksOOSList.isNotEmpty &&
                i < _remarksOOSList.length &&
                _remarksOOSList[i] != null
            ? _remarksOOSList[i]!
            : '';

        if (status == 'Delisted') {
          beginningValue = 'Delisted';
          deliveryValue = 'Delisted';
          endingValue = 'Delisted';
          endingWA = 'Delisted';
          endingSA = 'Delisted';
          remarksOOSValue = 'Delisted';
        } else {
          deliveryValue =
              int.tryParse(_deliveryControllers[i].text)?.toString() ?? '0';
          endingValue =
              int.tryParse(_endingControllers[i].text)?.toString() ?? '0';
          offtakeValue = double.tryParse(_offtakeControllers[i].text)
                  ?.toStringAsFixed(2) ??
              '0.00';
        }

        // Calculate offtake
        double beginningVal =
            double.tryParse(_beginningControllers[i].text) ?? 0;
        double delivery = double.tryParse(_deliveryControllers[i].text) ?? 0;
        double ending = double.tryParse(_endingControllers[i].text) ?? 0;
        double offtake = beginningVal + delivery - ending;

        if (status != 'Delisted') {
          if (offtake != 0 && ending != double.infinity && !ending.isNaN) {
            inventoryDaysLevel = ending / (offtake / 7);
          }
        }

        // Prepare expiry fields data
        List<Map<String, String>> expiryFieldsData = [];

// Ensure lists are not empty before calculating maxIndex
        if (_selectedMonths.isNotEmpty || _pcsControllers.isNotEmpty) {
          int maxIndex = max(_selectedMonths.length, _pcsControllers.length);

          for (int j = 0; j < maxIndex; j++) {
            // Fix: Ensure expiryMonth is always a valid String
            String expiryMonth =
                j < _selectedMonths.length ? _selectedMonths[j] ?? '' : '';
            String expiryPcs =
                j < _pcsControllers.length ? _pcsControllers[j].text : '';

            if (expiryMonth.isNotEmpty || expiryPcs.isNotEmpty) {
              expiryFieldsData.add({
                'expiryMonth': expiryMonth,
                'expiryPcs': expiryPcs,
              });
              print("Added expiry field: ${expiryFieldsData.last}");
            } else {
              print("Skipping empty field at index $j");
            }
          }
        } else {
          print("No expiry fields available.");
        }

        // Prepare the document to insert
        var newDocument = {
          'userEmail': widget.userEmail,
          'date': _dateControllers[i].text,
          'inputId': _inputIdControllers[i].text,
          'name': _nameControllers[i].text,
          'accountNameBranchManning': accountManning,
          'period': _selectedPeriod,
          'month': _monthControllers[i].text,
          'week': _weekControllers[i].text,
          'skuDescription': _skuDesControllers[i].text,
          'skuCode': _skuCodeControllers[i].text,
          'status': status,
          'beginning': beginningValue,
          'delivery': deliveryValue,
          'ending': endingValue,
          'endingSA': endingSA,
          'endingWA': endingWA,
          'offtake': offtakeValue,
          'inventoryDaysLevel':
              double.parse(inventoryDaysLevel.toStringAsFixed(2)),
          'noOfDaysOOS': noOfDaysOOSValue,
          'expiryFields': expiryFieldsData,
          'remarksOOS': remarksOOSValue,
          'isEditing': true,
        };

        // Log the final document before insertion
        print('Final Document to Insert: $newDocument');

        // Insert the new document into the collection
        await collection.insertOne(newDocument);
        print('New inventory item #${i + 1} inserted successfully.');
      }

      // Check if the widget is still mounted before navigating
      if (mounted) {
        Navigator.pop(context, true); // Indicate that editing is done
      }
    } catch (e) {
      print('Error inserting new inventory items: $e');
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

  bool _isFieldsEnabled(int index) {
    return _statusControllers[index].text == 'Carried';
  }

  void _resetFields(int index) {
    _deliveryControllers[index].clear();
    _endingControllers[index].clear();
    _offtakeControllers[index].clear();
    _endingSAControllers[index].clear();
    _endingWAControllers[index].clear();
    _IDLControllers[index].clear();
    _expiryFields.clear();
    _pcsControllers.clear();
    _selectedMonths.clear();
    _selectedNumberOfDaysOOS = null;
    _remarksOOS = null;
    _selectedNoDeliveryOption = null;
  }

  void _updateAllFields(int index, String value) {
    setState(() {
      _selectedPeriod = value;
      _isSaveEnabled = _selectedPeriod != null;

      String selectedMonth = '';
      String selectedWeek = '';

      // Determine the corresponding month and week
      switch (value) {
        case 'Mar24-Mar29':
          selectedMonth = 'March';
          selectedWeek = 'Week 13';
          break;
        case 'Mar31-Apr05':
          selectedMonth = 'March';
          selectedWeek = 'Week 14';
          break;
        case 'Apr07-Apr12':
          selectedMonth = 'April';
          selectedWeek = 'Week 15';
          break;
        case 'Apr14-Apr19': // Corrected to Monday-Saturday
          selectedMonth = 'April';
          selectedWeek = 'Week 16';
          break;
        case 'Apr21-Apr26': // Corrected to Monday-Saturday
          selectedMonth = 'April';
          selectedWeek = 'Week 17';
          break;
        case 'Apr28-May03': // Corrected to Monday-Saturday
          selectedMonth = 'April';
          selectedWeek = 'Week 18';
          break;
        case 'May05-May10': // Corrected to Monday-Saturday
          selectedMonth = 'May';
          selectedWeek = 'Week 19';
          break;
        case 'May12-May17':
          selectedMonth = 'May';
          selectedWeek = 'Week 20';
          break;
        case 'May19-May24':
          selectedMonth = 'May';
          selectedWeek = 'Week 21';
          break;
        case 'May26-May31':
          selectedMonth = 'May';
          selectedWeek = 'Week 22';
          break;
        case 'Jun02-Jun07':
          selectedMonth = 'June';
          selectedWeek = 'Week 23';
          break;
        case 'Jun09-Jun14':
          selectedMonth = 'June';
          selectedWeek = 'Week 24';
          break;
        case 'Jun16-Jun21':
          selectedMonth = 'June';
          selectedWeek = 'Week 25';
          break;
        case 'Jun23-Jun28':
          selectedMonth = 'June';
          selectedWeek = 'Week 26';
          break;
        case 'Jun30-Jul05':
          selectedMonth = 'June';
          selectedWeek = 'Week 27';
          break;
        case 'Jul07-Jul12':
          selectedMonth = 'July';
          selectedWeek = 'Week 28';
          break;
        case 'Jul14-Jul19':
          selectedMonth = 'July';
          selectedWeek = 'Week 29';
          break;
        case 'Jul21-Jul26':
          selectedMonth = 'July';
          selectedWeek = 'Week 30';
          break;
        case 'Jul28-Aug02':
          selectedMonth = 'July';
          selectedWeek = 'Week 31';
          break;
        case 'Aug04-Aug09':
          selectedMonth = 'August';
          selectedWeek = 'Week 32';
          break;
        case 'Aug11-Aug16':
          selectedMonth = 'August';
          selectedWeek = 'Week 33';
          break;
        case 'Aug18-Aug23':
          selectedMonth = 'August';
          selectedWeek = 'Week 34';
          break;
        case 'Aug25-Aug30':
          selectedMonth = 'August';
          selectedWeek = 'Week 35';
          break;
        case 'Sep01-Sep06':
          selectedMonth = 'September';
          selectedWeek = 'Week 36';
          break;
        case 'Sep08-Sep13':
          selectedMonth = 'September';
          selectedWeek = 'Week 37';
          break;
        case 'Sep15-Sep20':
          selectedMonth = 'September';
          selectedWeek = 'Week 38';
          break;
        case 'Sep22-Sep27':
          selectedMonth = 'September';
          selectedWeek = 'Week 39';
          break;
        case 'Sep29-Oct04':
          selectedMonth = 'September';
          selectedWeek = 'Week 40';
          break;
        case 'Oct06-Oct11':
          selectedMonth = 'October';
          selectedWeek = 'Week 41';
          break;
        case 'Oct13-Oct18':
          selectedMonth = 'October';
          selectedWeek = 'Week 42';
          break;
        case 'Oct20-Oct25':
          selectedMonth = 'October';
          selectedWeek = 'Week 43';
          break;
        case 'Oct27-Nov01':
          selectedMonth = 'October';
          selectedWeek = 'Week 44';
          break;
        case 'Nov03-Nov08':
          selectedMonth = 'November';
          selectedWeek = 'Week 45';
          break;
        case 'Nov10-Nov15':
          selectedMonth = 'November';
          selectedWeek = 'Week 46';
          break;
        case 'Nov17-Nov22':
          selectedMonth = 'November';
          selectedWeek = 'Week 47';
          break;
        case 'Nov24-Nov29':
          selectedMonth = 'November';
          selectedWeek = 'Week 48';
          break;
        case 'Dec01-Dec06':
          selectedMonth = 'December';
          selectedWeek = 'Week 49';
          break;
        case 'Dec08-Dec13':
          selectedMonth = 'December';
          selectedWeek = 'Week 50';
          break;
        case 'Dec15-Dec20':
          selectedMonth = 'December';
          selectedWeek = 'Week 51';
          break;
        case 'Dec22-Dec27':
          selectedMonth = 'December';
          selectedWeek = 'Week 52';
          break;
        case 'Dec29-Jan03':
          selectedMonth = 'December';
          selectedWeek = 'Week 1';
          break;
        case 'Jan05-Jan10':
          selectedMonth = 'January';
          selectedWeek = 'Week 2';
          break;
      }

// Update all inventory items with the selected month & week
      for (int i = 0; i < _monthControllers.length; i++) {
        _monthControllers[i].text = selectedMonth;
        _weekControllers[i].text = selectedWeek;
      }

      // Update all inventory items with the selected month & week
      for (int i = 0; i < _monthControllers.length; i++) {
        _monthControllers[i].text = selectedMonth;
        _weekControllers[i].text = selectedWeek;
      }
    });
  }

  void _addExpiryField() {
    setState(() {
      if (_pcsControllers.length < 6) {
        // Limit to 6 expiry fields
        _pcsControllers.add(TextEditingController()); // Add a new controller
        _selectedMonths.add(''); // Use an empty string instead of null
        _expiryFields
            .add(_buildExpiryField(_pcsControllers.length - 1)); // Add widget
      }
    });
  }

  void _removeExpiryField(int index) {
    setState(() {
      if (index < _pcsControllers.length) {
        _pcsControllers[index].dispose(); // Dispose controller to free memory
        _pcsControllers.removeAt(index);
        _selectedMonths.removeAt(index);
        _expiryFields.removeAt(index);
      }
    });
  }

  void _updateExpiryField(int index, String selectedMonth, String pcsValue) {
    setState(() {
      if (index < _selectedMonths.length) {
        _selectedMonths[index] = selectedMonth;
      }
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

  Widget _buildInventorySection(int index) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (index == 1) ...[
        SizedBox(height: 16),
        Divider(thickness: 8, color: Color.fromARGB(255, 26, 20, 71)),
        SizedBox(height: 8),
      ],
      Center(
        child: Text(
          'INVENTORY #${index + 1}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      SizedBox(height: 16),
      Text(
        'Date',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 8),
      TextField(
        readOnly: true,
        controller: _dateControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
      SizedBox(height: 16),
      Text(
        'Input ID',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 8),
      TextField(
        readOnly: true,
        controller: _inputIdControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
      SizedBox(height: 16),
      Text(
        'Merchandiser',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 8),
      TextField(
        readOnly: true,
        controller: _nameControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
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
      SizedBox(height: 8),
      TextField(
        controller: _branchControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
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
                        if (value != null) {
                          String actualValue = value.split('-')[1];
                          print('Selected period: $value');
                          _updateAllFields(index, value);
                        }
                        checkSaveEnabled(
                            index); // This will properly update _isSaveEnabled
                      });
                    },
                    items: _periodItems,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
      SizedBox(height: 16),
      Text(
        'Month',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 8),
      TextFormField(
        controller: _monthControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        readOnly: true,
      ),
      SizedBox(height: 16),
      Text(
        'Week',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 8),
      TextFormField(
        controller: _weekControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        readOnly: true,
      ),
      SizedBox(height: 16),
      Text(
        'Category',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      // SizedBox(height: 8),
      // TextField(
      //   controller: _categoryControllers[index],
      //   decoration: InputDecoration(
      //     border: OutlineInputBorder(),
      //     contentPadding: EdgeInsets.symmetric(horizontal: 12),
      //   ),
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
      SizedBox(height: 8),
      TextField(
        controller: _skuDesControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        enabled: false,
      ),
      SizedBox(height: 16),
      Text(
        'SKU Code',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 8),
      TextField(
        controller: _skuCodeControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
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
      SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _statusControllers[index].text.isNotEmpty
            ? _statusControllers[index].text
            : null,
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
            _statusControllers[index].text = newValue!;

            if (newValue == 'Delisted') {
              // Clear other fields but leave the beginning value unchanged
              _deliveryControllers[index].clear(); // Clear delivery field
              _endingSAControllers[index].clear();
              _endingWAControllers[index].clear();
              _endingControllers[index].clear(); // Clear ending field
              _selectedNumberOfDaysOOSList[index] = null;
              _remarksOOSList[index] = null;

              _offtakeControllers[index].text =
                  '0.00'; // Reset offtake to '0.00'

              // The beginning value remains **unchanged** here
            } else if (newValue == 'Carried') {
              // If status changes to 'Carried', **do not reset or alter** the beginning value
              // Simply leave _beginningControllers[index].text as is (it will stay as it was)
            }

            // Update the save button state
            checkSaveEnabled(index);
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
      SizedBox(height: 8),
      TextField(
        controller: _beginningControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
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
      SizedBox(height: 8),
      TextField(
        controller: _deliveryControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        keyboardType: TextInputType.number,
        enabled: _isFieldsEnabled(index),
      ),
      SizedBox(height: 16),
      Text(
        'Ending (Selling Area)',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 8),
      TextField(
        controller: _endingSAControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        keyboardType: TextInputType.number,
        enabled: _isFieldsEnabled(index),
        onChanged: (_) => _calculateEnding(index),
      ),
      SizedBox(height: 16),
      Text(
        'Ending (Warehouse Area)',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 8),
      TextField(
        controller: _endingWAControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        keyboardType: TextInputType.number,
        enabled: _isFieldsEnabled(index),
        onChanged: (_) => _calculateEnding(index),
      ),
      SizedBox(height: 16),
      Text(
        'Ending',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 8),
      TextField(
        readOnly: true,
        controller: _endingControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        keyboardType: TextInputType.number,
        enabled: _isFieldsEnabled(index),
      ),
      SizedBox(height: 20),
      Text(
        'Expiry Pcs',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 8),
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: (_expiryFields.length > index)
                ? _expiryFields[index]
                : SizedBox.shrink(),
          ),
        ],
      ),
      SizedBox(height: 16),
      Center(
        child: OutlinedButton(
          onPressed: _isFieldsEnabled(index) ? _addExpiryField : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              width: 2.0,
              color: _isFieldsEnabled(index)
                  ? Color.fromARGB(255, 26, 20, 71)
                  : Colors.grey,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            'Add Expiry',
            style: TextStyle(
              color: _isFieldsEnabled(index) ? Colors.black : Colors.grey,
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
      SizedBox(height: 8),
      TextField(
        controller: _offtakeControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        keyboardType: TextInputType.number,
        readOnly: true,
        enabled: _isFieldsEnabled(index),
      ),
      SizedBox(height: 16),
      Text(
        'Inventory Days Level',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 8),
      TextField(
        controller: _IDLControllers[index],
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        keyboardType: TextInputType.number,
        readOnly: true,
        enabled: _isFieldsEnabled(index),
      ),
      SizedBox(height: 16),
      Text(
        'No. of Days OOS',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 8),
      DropdownButtonFormField<int>(
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          enabled: _isFieldsEnabled(index),
        ),
        value: (index < _selectedNumberOfDaysOOSList.length)
            ? _selectedNumberOfDaysOOSList[index]
            : null, // Prevent accessing out of range
        onChanged: _isFieldsEnabled(index)
            ? (int? newValue) {
                setState(() {
                  if (index < _selectedNumberOfDaysOOSList.length) {
                    _selectedNumberOfDaysOOSList[index] = newValue;
                  }

                  // Reset fields when No. of Days OOS is 0
                  if (newValue == 0) {
                    _remarksOOSList[index] = null;
                  }

                  checkSaveEnabled(index);
                });
              }
            : null,

        items: List.generate(8, (i) {
          return DropdownMenuItem<int>(
            value: i,
            child: Text(i.toString()),
          );
        }),
      ),
      if (_selectedNumberOfDaysOOSList[index] != null &&
          _selectedNumberOfDaysOOSList[index]! > 0 &&
          _isFieldsEnabled(index)) ...[
        SizedBox(height: 16),
        Text(
          'Remarks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
            labelText: 'Enter Remarks', // Placeholder for input
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _remarksOOSList[index] = value.trim(); // Ensure no extra spaces

              checkSaveEnabled(index); // Ensure save button is updated
            });
          },
          initialValue: _remarksOOSList[index], // Preserve previous input
        ),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'INVENTORY FOR NEXT WEEK',
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
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loop through each inventory item and build its UI
                for (int index = 0;
                    index < widget.inventoryItems.length;
                    index++)
                  _buildInventorySection(index),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        widget.onCancel();
                        Navigator.of(context).pop();
                      },
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.symmetric(vertical: 15),
                        ),
                        minimumSize: MaterialStateProperty.all<Size>(
                          const Size(150, 50),
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromARGB(255, 26, 20, 71)),
                      ),
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
                          ? () async {
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
                                          Navigator.of(context).pop(false);
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                        child: Text('Confirm'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmed ?? false) {
                                _saveChanges();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Changes saved successfully'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                widget.onSave();
                                Navigator.pop(context);
                              }
                            }
                          : null, // Disable if no valid inventory
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.symmetric(vertical: 15),
                        ),
                        minimumSize: MaterialStateProperty.all<Size>(
                          const Size(150, 50),
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(
                          _isSaveEnabled
                              ? Color.fromARGB(255, 26, 20, 71)
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
          ),
        ),
      ),
    );
  }
}

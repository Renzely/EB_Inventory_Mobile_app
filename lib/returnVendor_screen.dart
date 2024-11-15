// ignore_for_file: non_constant_identifier_names, unused_import, depend_on_referenced_packages, prefer_const_constructors, use_key_in_widget_constructors, camel_case_types, prefer_final_fields, library_private_types_in_public_api, prefer_const_constructors_in_immutables, avoid_print, use_build_context_synchronously
import 'dart:math';
import 'package:demo_app/dashboard_screen.dart';
import 'package:demo_app/dbHelper/constant.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class ReturnVendor extends StatefulWidget {
  final String userName;
  final String userLastName;
  final String userEmail;
  final String userMiddleName;
  final String userContactNum;

  ReturnVendor({
    required this.userName,
    required this.userLastName,
    required this.userEmail,
    required this.userContactNum,
    required this.userMiddleName,
  });

  @override
  _ReturnVendorState createState() => _ReturnVendorState();
}

class _ReturnVendorState extends State<ReturnVendor> {
  late String selectedOutlet = ''; // Initialize with an empty string
  late String selectedItem = ''; // Initialize with an empty string
  DateTime? selectedExpiryDate;
  late DateTime selectedDate = DateTime.now(); // Initialize with current date
  String merchandiserName = '';

  double? amount;
  double? quantity;
  String total = '';
  final TextEditingController totalController = TextEditingController();

  List<String> reasonOptions = [
    'Expired',
    'Damaged Carrier',
    'Missing Bottle',
    'Sampling',
    'Near Expiry',
    'Others'
  ];
  List<String> remarkOptions = [
    'Disposed',
    'Still In Store',
    'Depleted',
    'Pulled Out',
    'Others'
  ];

  String? selectedReason;
  String? selectedRemark;

  bool isOtherReasonSelected = false;
  bool isOtherRemarkSelected = false;
  String customReason = '';
  String customRemark = '';
  String selectedCategory = '';
  String inputId = '';
  List<String> outletOptions = [];
  List<String> itemOptions = [];

  bool isSaveEnabled = false; // Ensure this is initialized properly

  // Add fetchOutlets method to fetch outlets from the database
  Future<void> fetchOutlets() async {
    try {
      final db = await mongo.Db.create(INVENTORY_CONN_URL);
      await db.open();

      final collection = db.collection(USER_NEW);
      final Map<String, dynamic>? userDoc = await collection
          .findOne(mongo.where.eq('emailAddress', widget.userEmail));

      if (userDoc != null) {
        print('User document found: $userDoc');
        setState(() {
          outletOptions = userDoc['accountNameBranchManning']
              .cast<String>(); // Convert to List<String>
          selectedOutlet = outletOptions.isNotEmpty ? outletOptions.first : '';
        });
      } else {
        print('No user document found for email: ${widget.userEmail}');
      }

      await db.close();
    } catch (e) {
      print('Error fetching outlets from database: $e');
    }
  }

  void fetchDataFromDatabase(String userEmail) async {
    try {
      final db = await mongo.Db.create(INVENTORY_CONN_URL);
      await db.open();

      final collection = db.collection(USER_NEW);
      final Map<String, dynamic>? userDoc =
          await collection.findOne(mongo.where.eq('emailAddress', userEmail));

      if (userDoc != null) {
        setState(() {
          selectedOutlet = userDoc['accountNameBranchManning'][0] ?? '';
          // Assuming you want to select the first item in the array
          // Modify the index as needed based on your data structure
        });
      }

      await db.close();
    } catch (e) {
      print('Error fetching data from database: $e');
    }
  }

  Map<String, List<String>> _categoryToSkuDescriptions = {
    'Variant': [
      "Engkanto Live it Up Lager",
      "Engkanto High Hive Honey Ale",
      "Engkanto Paint Me Purple - Ube Lager",
      "Engkanto Mango Nation Hazy IPA",
      "Engkanto Green Lava Double IPA",
    ],
  };

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate!,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        // Set expiry date based on business logic (e.g., one year from selection)
        selectedExpiryDate =
            DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      });
    }
  }

  void _selectExpiryDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedExpiryDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedExpiryDate = pickedDate;
        checkSaveEnabled();
      });
    }
  }

  String formatDate(DateTime? date) {
    return date != null ? DateFormat('ddMMMyy').format(date) : 'SELECT DATE';
  }

  @override
  void dispose() {
    totalController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    if (amount != null && quantity != null) {
      double calculatedTotal = amount! * quantity!;
      if (calculatedTotal % 1 == 0) {
        total = calculatedTotal.toStringAsFixed(0);
      } else {
        total = calculatedTotal.toStringAsFixed(2);
      }
      totalController.text = total; // Update controller text
    } else {
      total = '';
      totalController.text = total;
    }
  }

  @override
  void initState() {
    super.initState();

    amount = null;
    quantity = null;

    selectedReason = null;
    selectedRemark = null;

    // _addExpiryField();
    fetchDataFromDatabase(widget.userEmail);
    if (_categoryToSkuDescriptions.isNotEmpty) {
      selectedCategory = _categoryToSkuDescriptions.keys.first;
    }
    updateItemOptions(selectedCategory);
    fetchOutlets(); // Call fetchOutlets when the widget is initialized
    inputId = generateInputID();
  }

  void updateItemOptions(String category) {
    setState(() {
      switch (category) {
        case 'Variant':
          itemOptions = [
            "Engkanto Live it Up Lager",
            "Engkanto High Hive Honey Ale",
            "Engkanto Paint Me Purple - Ube Lager",
            "Engkanto Mango Nation Hazy IPA",
            "Engkanto Green Lava Double IPA",
          ];
          break;

        default:
          itemOptions = [];
      }
      selectedItem = itemOptions.isNotEmpty ? itemOptions.first : '';
    });
  }

  String generateInputID() {
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    var random =
        Random().nextInt(10000); // Generate a random number between 0 and 9999
    var paddedRandom =
        random.toString().padLeft(4, '0'); // Ensure it has 4 digits
    return '2000$paddedRandom';
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
                'Return to Vendor',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text(
                      'RTV No.',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      initialValue: generateInputID(),
                      enabled: false,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        hintText: 'Auto-generated Input ID',
                      ),
                    ),
                    Text(
                      'DATE',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Container(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                enabled: false,
                                border: OutlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12),
                                hintText: DateFormat('yyyy-MM-dd')
                                    .format(selectedDate),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'MERCHANDISER',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextFormField(
                      enabled: false,
                      initialValue: '${widget.userName} ${widget.userLastName}',
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        labelText: '',
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'OUTLET',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedOutlet,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: outletOptions.map((String outlet) {
                        return DropdownMenuItem(
                          value: outlet,
                          child: Text(outlet),
                        );
                      }).toList(),
                      onChanged: outletOptions.length == 1
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedOutlet = newValue;
                                });
                              }
                            },
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _categoryToSkuDescriptions.keys
                          .map((String category) {
                        return OutlinedButton(
                          onPressed: () => _toggleDropdown(category),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              width: 2.0,
                              color: selectedCategory == category
                                  ? Color.fromARGB(255, 26, 20, 71)
                                  : Colors.blueGrey.shade200,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(color: Colors.black),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'MATERIAL DESCRIPTION',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedItem,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: itemOptions.map((String item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: SizedBox(
                            width: 300,
                            child: Tooltip(
                              message: item,
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedItem = newValue;
                            checkSaveEnabled();
                          });
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    Text(
                      'EXPIRY DATE'.toUpperCase(),
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey), // Border around the box
                        borderRadius:
                            BorderRadius.circular(5.0), // Rounded corners
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 1, horizontal: 8), // Padding inside the box
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Align the content centrally
                        children: [
                          ElevatedButton(
                            onPressed: () => _selectExpiryDate(
                                context), // Call the expiry date picker
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // Button color
                              elevation: 0, // Remove button elevation
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  formatDate(selectedExpiryDate)
                                      .toUpperCase(), // Display the selected expiry date
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        Text(
                          'AMOUNT',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Enter Amount',
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            setState(() {
                              amount =
                                  double.tryParse(value.replaceAll(',', '.'));
                              _calculateTotal();
                              checkSaveEnabled();
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Quantity',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Enter Quantity',
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            setState(() {
                              quantity =
                                  double.tryParse(value.replaceAll(',', '.'));
                              _calculateTotal();
                              checkSaveEnabled();
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        Text(
                          'TOTAL',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                          readOnly: true,
                          controller: totalController,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'REASON',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        DropdownButtonFormField<String>(
                          value: selectedReason,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                          hint: Text(
                              'Please select a reason'), // Show hint text initially
                          items: reasonOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedReason = newValue;
                                isOtherReasonSelected = newValue == 'Others';
                                if (isOtherReasonSelected) customReason = '';
                                checkSaveEnabled();
                              });
                            }
                          },
                        ),
                        if (isOtherReasonSelected)
                          TextFormField(
                            initialValue: customReason,
                            decoration: InputDecoration(
                              hintText: 'Enter custom reason',
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onChanged: (value) {
                              setState(() {
                                customReason = value;
                                checkSaveEnabled();
                              });
                            },
                          ),
                        SizedBox(height: 16),
                        Text(
                          'REMARKS',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        DropdownButtonFormField<String>(
                          value: selectedRemark,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                          hint: Text(
                              'Please select a remark'), // Show hint text initially
                          items: remarkOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedRemark = newValue;
                                isOtherRemarkSelected = newValue == 'Others';
                                if (isOtherRemarkSelected) customRemark = '';
                                checkSaveEnabled();
                              });
                            }
                          },
                        ),
                        if (isOtherRemarkSelected)
                          TextFormField(
                            initialValue: customRemark,
                            decoration: InputDecoration(
                              hintText: 'Enter custom remarks',
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onChanged: (value) {
                              setState(() {
                                customRemark = value;
                                checkSaveEnabled();
                              });
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => RTV(
                                  userName: widget.userName,
                                  userLastName: widget.userLastName,
                                  userEmail: widget.userEmail,
                                  userContactNum: widget.userContactNum,
                                  userMiddleName: widget.userMiddleName,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Color.fromARGB(255, 26, 20, 71),
                            minimumSize: Size(150, 50),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed:
                              isSaveEnabled ? _confirmSaveReturnToVendor : null,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: isSaveEnabled
                                ? Color.fromARGB(255, 26, 20, 71)
                                : Colors.grey,
                            minimumSize: Size(150, 50),
                          ),
                          child: Text(
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
          ),
        ));
  }

  void updateDropdownValue(String newValue, bool isOther) {
    setState(() {
      if (newValue == 'Others') {
        if (isOther) {
          customReason = '';
          customRemark = '';
        }
        isOtherReasonSelected = true;
        isOtherRemarkSelected = true;
      } else {
        if (isOther) {
          selectedReason = newValue;
          isOtherReasonSelected = false;
        } else {
          selectedRemark = newValue;
          isOtherRemarkSelected = false;
        }
      }
      checkSaveEnabled();
    });
  }

  void _toggleDropdown(String value) {
    setState(() {
      selectedCategory = value;
      updateItemOptions(selectedCategory);
      //updateDropdownValue(value, isOther);
    });
  }

  void checkSaveEnabled() {
    setState(() {
      isSaveEnabled = amount != null &&
          quantity != null &&
          total.isNotEmpty &&
          selectedItem != null && // Check if a material description is selected
          selectedExpiryDate != null && // Check if an expiry date is selected
          (selectedReason != null &&
              (selectedReason != 'Others' || customReason.isNotEmpty)) &&
          (selectedRemark != null &&
              (selectedRemark != 'Others' || customRemark.isNotEmpty));
    });
  }

  void _confirmSaveReturnToVendor() async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Save Confirmation'),
          content: Text('Do you want to save this Return to Vendor?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false if cancelled
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true if confirmed
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      _saveReturnToVendor();
      // Navigate back to ReturnToVendor screen
      Navigator.of(context).pop();
    }
  }

  void _saveReturnToVendor() async {
    try {
      final db = await mongo.Db.create(INVENTORY_CONN_URL);
      await db.open();

      final collection = db.collection(USER_RTV);

      final objectId = ObjectId();

      String reasonValue =
          isOtherReasonSelected ? customReason : selectedReason!;
      String remarkValue =
          isOtherRemarkSelected ? customRemark : selectedRemark!;

      // Format the expiry date as requested: ddMMMyy
      String formattedExpiryDate = selectedExpiryDate != null
          ? '${DateFormat('ddMMMyy').format(selectedExpiryDate!)}'.toUpperCase()
          : '';

      print("Formatted expiry date: $formattedExpiryDate"); // Debug print

      // Construct the document to be inserted
      final document = {
        '_id': objectId,
        'inputId': inputId,
        'userEmail': widget.userEmail,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'merchandiserName': '${widget.userName} ${widget.userLastName}',
        'outlet': selectedOutlet,
        'category': selectedCategory,
        'item': selectedItem,
        'expiryDate': formattedExpiryDate,
        'amount': amount,
        'quantity': quantity,
        'total': total,
        'remarks': remarkValue,
        'reason': reasonValue
      };

      // Insert the document into the collection
      await collection.insert(document);

      await db.close();

      print('Return to Vendor data saved successfully!');
    } catch (e) {
      print('Error saving Return to Vendor data: $e');
    }
  }
}

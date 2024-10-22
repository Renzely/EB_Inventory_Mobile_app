// ignore_for_file: must_be_immutable, prefer_const_constructors, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, library_private_types_in_public_api, unnecessary_string_interpolations, sort_child_properties_last, avoid_print, use_rethrow_when_possible, depend_on_referenced_packages
import 'package:demo_app/editInventory_screen.dart';
// import 'package:demo_app/editRTV_screen.dart';
import 'package:demo_app/inventoryAdd_screen.dart';
import 'package:demo_app/login_screen.dart';
import 'package:demo_app/dbHelper/constant.dart';
import 'package:demo_app/dbHelper/mongodb.dart';
import 'package:demo_app/dbHelper/mongodbDraft.dart';
import 'package:demo_app/provider.dart';
import 'package:demo_app/returnVendor_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Attendance extends StatelessWidget {
  final String userName;
  final String userLastName;
  final String userEmail;
  String userMiddleName;
  String userContactNum;

  Attendance({
    required this.userName,
    required this.userLastName,
    required this.userEmail,
    required this.userContactNum,
    required this.userMiddleName,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: SideBarLayout(
          title: "Attendance",
          mainContent: SingleChildScrollView(
            // Wrap the Column with SingleChildScrollView
            child: Column(
              children: [
                DateTimeWidget(),
                AttendanceWidget(
                    userEmail: userEmail), // Pass the userEmail here
              ],
            ),
          ),
          userName: userName,
          userLastName: userLastName,
          userEmail: userEmail,
          userContactNum: userContactNum,
          userMiddleName: userMiddleName,
        ));
  }
}

class AttendanceWidget extends StatefulWidget {
  final String userEmail;

  AttendanceWidget({required this.userEmail});

  @override
  _AttendanceWidgetState createState() => _AttendanceWidgetState();
}

class _AttendanceWidgetState extends State<AttendanceWidget> {
  String? timeInLocation = 'No location';
  String? timeOutLocation = 'No location';
  bool _isTimeInLoading = false; // For Time In button loading state
  bool _isTimeOutLoading = false; // For Time Out button loading state

  @override
  void initState() {
    super.initState();
    _initializeAttendanceStatus();
    _isTimeInLoading = false;
    _isTimeOutLoading = false;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  void _initializeAttendanceStatus() async {
    final attendanceModel =
        Provider.of<AttendanceModel>(context, listen: false);

    // Fetch attendance status from the database
    var attendanceStatus =
        await MongoDatabase.getAttendanceStatus(widget.userEmail);

    if (attendanceStatus != null) {
      String? timeInFormatted = _formatTime(attendanceStatus['timeIn']);
      String? timeOutFormatted = _formatTime(attendanceStatus['timeOut']);

      if (timeInFormatted != null) {
        attendanceModel.updateTimeIn(timeInFormatted);
      }

      if (timeOutFormatted != null) {
        attendanceModel.updateTimeOut(timeOutFormatted);
      }

      attendanceModel.setIsTimeInRecorded(attendanceStatus['timeIn'] != null);
      attendanceModel.setIsTimeOutRecorded(attendanceStatus['timeOut'] != null);

      String timeInLocation =
          attendanceStatus['timeInLocation'] ?? 'No location';
      String timeOutLocation =
          attendanceStatus['timeOutLocation'] ?? 'No location';

      attendanceModel.updateTimeInLocation(timeInLocation);
      attendanceModel.updateTimeOutLocation(timeOutLocation);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('timeInLocation', timeInLocation);
      await prefs.setString('timeOutLocation', timeOutLocation);

      setState(() {
        this.timeInLocation = timeInLocation;
        this.timeOutLocation = timeOutLocation;
      });
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        timeInLocation = prefs.getString('timeInLocation') ?? 'No location';
        timeOutLocation = prefs.getString('timeOutLocation') ?? 'No location';
      });
    }
  }

  String? _formatTime(String? time) {
    if (time == null) return null;
    try {
      DateTime dateTime = DateTime.parse(time);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      print('Error formatting time: $e');
      return null;
    }
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String> _getAddressFromLatLong(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    return "${place.street}, ${place.locality}, ${place.administrativeArea}";
  }

  Future<void> _confirmAndRecordTimeIn(BuildContext context) async {
    // Check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackbar(
          context, 'Please enable location services to mark attendance.');
      return;
    }

    // Check if location permission is granted
    bool permissionGranted = await checkLocationPermission();
    if (!permissionGranted) {
      _showSnackbar(
          context, 'Location permission denied. Please allow access.');
      return;
    }

    // Proceed with confirmation and recording time in
    bool confirmed = await _showConfirmationDialog('Time In');
    if (confirmed) {
      setState(() {
        _isTimeInLoading = true; // Start loading
      });

      try {
        _recordTimeIn(context); // Existing code to record time in
      } finally {
        setState(() {
          _isTimeInLoading =
              false; // Ensure loading stops even if an error occurs
        });
      }
    }
  }

  Future<void> _confirmAndRecordTimeOut(BuildContext context) async {
    bool confirmed = await _showConfirmationDialog('Time Out');
    if (confirmed) {
      setState(() {
        _isTimeOutLoading = true; // Start loading
      });

      try {
        _recordTimeOut(context);
      } finally {
        setState(() {
          _isTimeOutLoading =
              false; // Ensure loading stops even if an error occurs
        });
      }
    }
  }

  void _recordTimeIn(BuildContext context) async {
    final attendanceModel =
        Provider.of<AttendanceModel>(context, listen: false);
    String currentTimeIn = DateFormat('h:mm a').format(DateTime.now());

    Position? position = await _getCurrentLocation();
    String location = 'No location';
    if (position != null) {
      location = await _getAddressFromLatLong(position);
      setState(() {
        timeInLocation = location;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('timeInLocation', location);
    }

    setState(() {
      _isTimeInLoading = true; // Start loading
    });

    try {
      var result = await MongoDatabase.logTimeIn(widget.userEmail, location);
      if (result == "Success") {
        attendanceModel.updateTimeIn(currentTimeIn);
        attendanceModel.setIsTimeInRecorded(true);
        print('Time In recorded successfully for ${widget.userEmail}');
        _showSnackbar(context, 'Time In recorded successfully');
      } else {
        print('Failed to record Time In for ${widget.userEmail}');
        _showSnackbar(context, 'Failed to record Time In');
      }
    } catch (e) {
      print('Error recording time in: $e');
      _showSnackbar(context, 'Error recording Time In');
    } finally {
      setState(() {
        _isTimeInLoading = false; // Stop loading after process completes
      });
    }
  }

  void _recordTimeOut(BuildContext context) async {
    final attendanceModel =
        Provider.of<AttendanceModel>(context, listen: false);
    String currentTimeOut = DateFormat('h:mm a').format(DateTime.now());

    Position? position = await _getCurrentLocation();
    String location = 'No location';
    if (position != null) {
      location = await _getAddressFromLatLong(position);
      setState(() {
        timeOutLocation = location;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('timeOutLocation', location);
    }

    setState(() {
      _isTimeOutLoading = true; // Start loading
    });

    try {
      var result = await MongoDatabase.logTimeOut(widget.userEmail, location);
      if (result == "Success") {
        attendanceModel.updateTimeOut(currentTimeOut);
        attendanceModel.setIsTimeOutRecorded(true);
        print('Time Out recorded successfully for ${widget.userEmail}');
        _showSnackbar(context, 'Time Out recorded successfully');
      } else {
        print('Failed to record Time Out for ${widget.userEmail}');
        _showSnackbar(context, 'Failed to record Time Out');
      }
    } catch (e) {
      print('Error recording time out: $e');
      _showSnackbar(context, 'Error recording Time Out');
    } finally {
      setState(() {
        _isTimeOutLoading = false; // Stop loading after process completes
      });
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Consumer<AttendanceModel>(
        builder: (context, attendanceModel, child) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  "TIME IN",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      !attendanceModel.isTimeInRecorded && !_isTimeInLoading
                          ? () => _confirmAndRecordTimeIn(context)
                          : null,
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.symmetric(vertical: 30),
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(
                      const Size(150, 50),
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) {
                        if (!attendanceModel.isTimeInRecorded) {
                          return Colors.grey;
                        } else {
                          return Colors.grey;
                        }
                      },
                    ),
                  ),
                  child: _isTimeInLoading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          "Time In",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                ),
                SizedBox(height: 30),
                Text(
                  "Time In: ${attendanceModel.timeIn ?? 'Not recorded'}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "Location: $timeInLocation",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  "TIME OUT",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: attendanceModel.isTimeInRecorded &&
                          !attendanceModel.isTimeOutRecorded &&
                          !_isTimeOutLoading
                      ? () => _confirmAndRecordTimeOut(context)
                      : null,
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.symmetric(vertical: 30),
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(
                      const Size(150, 50),
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) {
                        if (attendanceModel.isTimeInRecorded &&
                            !attendanceModel.isTimeOutRecorded) {
                          return Colors.red;
                        } else {
                          return Colors.grey;
                        }
                      },
                    ),
                  ),
                  child: _isTimeOutLoading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          "Time Out",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                ),
                SizedBox(height: 30),
                Text(
                  "Time Out: ${attendanceModel.timeOut ?? 'Not recorded'}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "Location: $timeOutLocation",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String action) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm $action'),
            content: Text('Are you sure you want to record $action?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class Inventory extends StatefulWidget {
  final String userName;
  final String userLastName;
  final String userEmail;
  final String userContactNum;
  final String userMiddleName;

  const Inventory({
    required this.userName,
    required this.userLastName,
    required this.userEmail,
    required this.userContactNum,
    required this.userMiddleName,
  });

  @override
  _InventoryState createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  int pageSize = 5;
  int currentPage = 0;
  late Future<List<InventoryItem>> _futureInventory;
  bool _sortByLatest = true; // Default to sorting by latest date
  Map<String, bool> itemEditingStatus = {};
  List<InventoryItem> currentPageItems = []; // Populate with your items
  Map<String, bool> editingStates = {};
  // // SharedPreferences Helper Functions
  // Future<void> saveEditingStatus(
  //     String inputId, bool status, String userEmail) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   try {
  //     String key = '${userEmail}_$inputId'; // Include the user email in the key
  //     print('Saving editing status for key: $key with status: $status');
  //     await prefs.setBool(key, status);
  //   } catch (e) {
  //     print('Error saving editing status: $e');
  //   }
  // }

  // Future<bool> loadEditingStatus(String inputId, String userEmail) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   String key = '${userEmail}_$inputId'; // Include the user email in the key
  //   bool status = prefs.getBool(key) ?? false;
  //   print('Loaded editing status for key: $key - Status: $status');
  //   return status;
  // }

  // Future<void> clearEditingStatus(String inputId, String userEmail) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   String key = '${userEmail}_$inputId'; // Include the user email in the key
  //   await prefs.remove(key);
  // }

  // Function to fetch editing status from MongoDB

  Future<bool> _getEditingStatus(String inputId, String userEmail) async {
    return await MongoDatabase.getEditingStatus(inputId, userEmail);
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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _futureInventory = _fetchInventoryData();
    });
  }

  Future<List<InventoryItem>> _fetchInventoryData() async {
    try {
      final db = await mongo.Db.create(INVENTORY_CONN_URL);
      await db.open();
      final collection = db.collection(USER_INVENTORY);

      // Query only items that match the current user's email
      final List<Map<String, dynamic>> results =
          await collection.find({'userEmail': widget.userEmail}).toList();

      await db.close();

      List<InventoryItem> inventoryItems =
          results.map((data) => InventoryItem.fromJson(data)).toList();
      // Sort inventory items based on _sortByLatest flag
      inventoryItems.sort((a, b) {
        // Extract the numeric part from the 'week' string using RegExp
        int weekA =
            int.tryParse(RegExp(r'\d+').firstMatch(b.week)?.group(0) ?? '0') ??
                0;
        int weekB =
            int.tryParse(RegExp(r'\d+').firstMatch(a.week)?.group(0) ?? '0') ??
                0;

        if (_sortByLatest) {
          return weekB
              .compareTo(weekA); // Sort by latest to oldest (descending)
        } else {
          return weekA.compareTo(weekB); // Sort by oldest to latest (ascending)
        }
      });

      return inventoryItems;
    } catch (e) {
      print('Error fetching inventory data: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          body: SideBarLayout(
            title: "Inventory",
            mainContent: RefreshIndicator(
              onRefresh: () async {
                _fetchData();
              },
              child: FutureBuilder<List<InventoryItem>>(
                future: _futureInventory,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.grey,
                        backgroundColor: Colors.transparent,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    List<InventoryItem> inventoryItems = snapshot.data ?? [];
                    if (inventoryItems.isEmpty) {
                      return Center(
                        child: Text(
                          'No inventory created',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      );
                    } else {
                      // Calculate total number of pages
                      int totalPages =
                          (inventoryItems.length / pageSize).ceil();

                      // Ensure currentPage does not exceed totalPages
                      currentPage = currentPage.clamp(0, totalPages - 1);

                      // Calculate startIndex and endIndex for current page
                      int startIndex = currentPage * pageSize;
                      int endIndex = (currentPage + 1) * pageSize;

                      // Slice the list based on current page and page size
                      List<InventoryItem> currentPageItems =
                          inventoryItems.reversed.toList().sublist(startIndex,
                              endIndex.clamp(0, inventoryItems.length));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back),
                                onPressed: currentPage > 0
                                    ? () {
                                        setState(() {
                                          currentPage--;
                                        });
                                      }
                                    : null,
                              ),
                              Text(
                                'Page ${currentPage + 1} of $totalPages',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_forward),
                                onPressed: currentPage < totalPages - 1
                                    ? () {
                                        setState(() {
                                          currentPage++;
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                          Expanded(
                            child: ListView.builder(
                                itemCount: currentPageItems.length,
                                itemBuilder: (context, index) {
                                  InventoryItem item = currentPageItems[index];
                                  return FutureBuilder<bool>(
                                    key: ValueKey(item.inputId),
                                    future: _getEditingStatus(
                                        item.inputId, widget.userEmail),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return ListTile(
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(item.week),
                                              Icon(Icons
                                                  .error), // Show error icon
                                            ],
                                          ),
                                        );
                                      }

                                      bool isEditing = snapshot.data ??
                                          true; // Use false as default
                                      print(
                                          'Item ${item.inputId} isEditing: $isEditing');

                                      return ListTile(
                                        title: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(item.week),
                                            IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: item.status ==
                                                          'Carried' &&
                                                      !isEditing
                                                  ? () async {
                                                      await _updateEditingStatus(
                                                          item.inputId,
                                                          widget.userEmail,
                                                          false); // Start editing
                                                      bool hasSavedChanges =
                                                          false; // Track if changes are saved

                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              EditInventoryScreen(
                                                            inventoryItem: item,
                                                            userEmail: widget
                                                                .userEmail,
                                                            userContactNum: widget
                                                                .userContactNum,
                                                            userLastName: widget
                                                                .userLastName,
                                                            userMiddleName: widget
                                                                .userMiddleName,
                                                            userName:
                                                                widget.userName,
                                                            onCancel: () async {
                                                              // Reset editing status back to false (not editing anymore)
                                                              await _updateEditingStatus(
                                                                  item.inputId,
                                                                  widget
                                                                      .userEmail,
                                                                  false);
                                                              setState(
                                                                  () {}); // Refresh UI after cancel
                                                            },
                                                            onSave: () async {
                                                              hasSavedChanges =
                                                                  true; // Indicate that changes have been saved
                                                            },
                                                          ),
                                                        ),
                                                      );

                                                      // Only update editing status to true if changes were saved
                                                      if (hasSavedChanges) {
                                                        await _updateEditingStatus(
                                                            item.inputId,
                                                            widget.userEmail,
                                                            true);
                                                      }

                                                      setState(
                                                          () {}); // Refresh UI after editing
                                                    }
                                                  : null, // Disable button if isEditing is true
                                            ),
                                          ],
                                        ),
                                        subtitle: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 1.0,
                                            ),
                                          ),
                                          padding: EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Date: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.date}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Input ID: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.inputId}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Merchandiser: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.name}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Account Name Branch Manning: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.accountNameBranchManning}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Period: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.period}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Month: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.month}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Week: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.week}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Category: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text('${item.category}'),
                                              SizedBox(height: 10),
                                              Text(
                                                'SKU Description: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.skuDescription}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Products: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.products}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'SKU Code: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.skuCode}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Status: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.status}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Beginning (Selling Area): ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.beginningSA}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Beginning (Warehouse Area): ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.beginningWA}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Ending (Selling Area): ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.endingWA}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Ending (Warehouse Area): ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.endingWA}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Beginning: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.beginning}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Delivery: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.delivery}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Ending: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.ending}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Expiration: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: item.expiryFields
                                                    .map((expiry) {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Expiry Date: ${expiry['expiryMonth']}',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black),
                                                      ),
                                                      Text(
                                                        'Quantity: ${expiry['expiryPcs']}',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black),
                                                      ),
                                                      if (expiry.containsKey(
                                                          'manualPcsInput')) // Check if 'manualPcsInput' exists
                                                        Text(
                                                          'Manual PCS Input: ${expiry['expiryPcs']}',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                      SizedBox(
                                                          height:
                                                              10), // Adjust spacing as needed
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Offtake: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.offtake}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Inventory Days Level: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.inventoryDaysLevel}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Number of Days OOS: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.noOfDaysOOS}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Remarks: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.remarksOOS}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Reason: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                '${item.reasonOOS}',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                          )
                        ],
                      );
                    }
                  }
                },
              ),
            ),
            appBarActions: [
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
                onPressed: () {
                  _fetchData();
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    _sortByLatest = value == 'latestToOldest';
                    _fetchData(); // Reload data based on new sort order
                  });
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'latestToOldest',
                    child: Text('Sort by Latest to Oldest'),
                  ),
                  PopupMenuItem<String>(
                    value: 'oldestToLatest',
                    child: Text('Sort by Oldest to Latest'),
                  ),
                ],
              ),
            ],
            userName: widget.userName,
            userLastName: widget.userLastName,
            userEmail: widget.userEmail,
            userContactNum: widget.userContactNum,
            userMiddleName: widget.userMiddleName,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddInventory(
                    userName: widget.userName,
                    userLastName: widget.userLastName,
                    userEmail: widget.userEmail,
                    userContactNum: widget.userContactNum,
                    userMiddleName: widget.userMiddleName,
                  ),
                ),
              );
            },
            child: Icon(
              Icons.assignment_add,
              color: Colors.white,
            ),
            backgroundColor: Colors.grey,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ));
  }
}

// class RTV extends StatefulWidget {
//   final String userName;
//   final String userLastName;
//   final String userEmail;
//   String userMiddleName;
//   String userContactNum;

//   RTV({
//     required this.userName,
//     required this.userLastName,
//     required this.userEmail,
//     required this.userContactNum,
//     required this.userMiddleName,
//   });

//   @override
//   _RTVState createState() => _RTVState();
// }

// class _RTVState extends State<RTV> {
//   late Future<List<ReturnToVendor>> _futureRTV;
//   bool _sortByLatest = true; // Default to sorting by latest date

//   @override
//   void initState() {
//     super.initState();
//     _fetchData();
//   }

//   void _fetchData() {
//     setState(() {
//       _futureRTV = _fetchRTVData();
//     });
//   }

//   Future<List<ReturnToVendor>> _fetchRTVData() async {
//     try {
//       final db = await mongo.Db.create(MONGO_CONN_URL);
//       await db.open();
//       final collection = db.collection(USER_RTV);

//       final List<Map<String, dynamic>> results =
//           await collection.find({'userEmail': widget.userEmail}).toList();

//       await db.close();

//       List<ReturnToVendor> rtvItems =
//           results.map((data) => ReturnToVendor.fromJson(data)).toList();

//       rtvItems.sort((a, b) {
//         if (_sortByLatest) {
//           return b.date.compareTo(a.date); // Sort by latest to oldest
//         } else {
//           return a.date.compareTo(b.date); // Sort by oldest to latest
//         }
//       });
//       return rtvItems;
//     } catch (e) {
//       print('Error fetching RTV data: $e');
//       throw e;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//         onWillPop: () async => false,
//         child: Scaffold(
//           body: SideBarLayout(
//             title: "Return To Vendor",
//             mainContent: RefreshIndicator(
//               onRefresh: () async {
//                 _fetchData();
//               },
//               child: FutureBuilder<List<ReturnToVendor>>(
//                   future: _futureRTV,
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return Center(
//                           child: CircularProgressIndicator(
//                         color: Colors.grey,
//                         backgroundColor: Colors.transparent,
//                       ));
//                     } else if (snapshot.hasError) {
//                       return Center(
//                         child: Text('Error: ${snapshot.error}'),
//                       );
//                     } else {
//                       List<ReturnToVendor> rtvItems = snapshot.data ?? [];
//                       if (rtvItems.isEmpty) {
//                         return Center(
//                           child: Text(
//                             'No RTV created',
//                             style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                                 color: Colors.black),
//                           ),
//                         );
//                       } else {
//                         return ListView.builder(
//                             itemCount: rtvItems.length,
//                             itemBuilder: (context, index) {
//                               ReturnToVendor item = rtvItems[index];
//                               bool isEditable = item.quantity == "Pending" &&
//                                   item.driverName == "Pending" &&
//                                   item.plateNumber == "Pending" &&
//                                   item.pullOutReason == "Pending";

//                               return ListTile(
//                                   title: Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Text(
//                                         '${item.date}',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.black),
//                                       ),
//                                       isEditable
//                                           ? IconButton(
//                                               icon: Icon(Icons.edit,
//                                                   color: Colors.black),
//                                               onPressed: () {
//                                                 Navigator.of(context).push(
//                                                   MaterialPageRoute(
//                                                     builder: (context) =>
//                                                         EditRTVScreen(
//                                                             item: item),
//                                                   ),
//                                                 );
//                                               },
//                                             )
//                                           : IconButton(
//                                               icon: Icon(Icons.edit,
//                                                   color: Colors.grey),
//                                               onPressed: null,
//                                             ),
//                                     ],
//                                   ),
//                                   subtitle: Container(
//                                     decoration: BoxDecoration(
//                                       color: Colors.grey.shade200,
//                                       border: Border.all(
//                                         color: Colors.black,
//                                         width: 1.0,
//                                       ),
//                                     ),
//                                     padding: EdgeInsets.all(8.0),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         RichText(
//                                           text: TextSpan(
//                                             children: [
//                                               TextSpan(
//                                                 text: 'Input ID: ',
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text: item.inputId,
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.normal,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         SizedBox(height: 10),
//                                         RichText(
//                                           text: TextSpan(
//                                             children: [
//                                               TextSpan(
//                                                 text: 'Date: ',
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text: item.date,
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.normal,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         SizedBox(height: 10),
//                                         RichText(
//                                           text: TextSpan(
//                                             children: [
//                                               TextSpan(
//                                                 text: 'Outlet: ',
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text: item.outlet,
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.normal,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         SizedBox(height: 10),
//                                         RichText(
//                                           text: TextSpan(
//                                             children: [
//                                               TextSpan(
//                                                 text: 'Category: ',
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text: item.category,
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.normal,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         SizedBox(height: 10),
//                                         RichText(
//                                           text: TextSpan(
//                                             children: [
//                                               TextSpan(
//                                                 text: 'Item: ',
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text: item.item,
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.normal,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         SizedBox(height: 10),
//                                         RichText(
//                                           text: TextSpan(
//                                             children: [
//                                               TextSpan(
//                                                 text: 'Quantity: ',
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text: item.quantity,
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.normal,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         SizedBox(height: 10),
//                                         RichText(
//                                           text: TextSpan(
//                                             children: [
//                                               TextSpan(
//                                                 text: 'Driver\'s Name: ',
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text: item.driverName,
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.normal,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         SizedBox(height: 10),
//                                         RichText(
//                                           text: TextSpan(
//                                             children: [
//                                               TextSpan(
//                                                 text: 'Plate Number: ',
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text: item.plateNumber,
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.normal,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         SizedBox(height: 10),
//                                         RichText(
//                                           text: TextSpan(
//                                             children: [
//                                               TextSpan(
//                                                 text: 'Pull Out Reason: ',
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text: item.pullOutReason,
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.normal,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ));
//                             });
//                       }
//                     }
//                   }),
//             ),
//             appBarActions: [
//               IconButton(
//                 icon: Icon(
//                   Icons.refresh,
//                   color: Colors.white,
//                 ),
//                 onPressed: () {
//                   _fetchData();
//                 },
//               ),
//               PopupMenuButton<String>(
//                 onSelected: (value) {
//                   setState(() {
//                     _sortByLatest = value == 'latestToOldest';
//                     _fetchData();
//                   });
//                 },
//                 itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//                   PopupMenuItem<String>(
//                     value: 'latestToOldest',
//                     child: Text('Sort by Latest to Oldest'),
//                   ),
//                   PopupMenuItem<String>(
//                     value: 'oldestToLatest',
//                     child: Text('Sort by Oldest to Latest'),
//                   ),
//                 ],
//               ),
//             ],
//             userName: widget.userName,
//             userLastName: widget.userLastName,
//             userEmail: widget.userEmail,
//             userContactNum: widget.userContactNum,
//             userMiddleName: widget.userMiddleName,
//           ),
//           floatingActionButton: FloatingActionButton(
//             onPressed: () {
//               Navigator.of(context).push(MaterialPageRoute(
//                 builder: (context) => ReturnVendor(
//                   userName: widget.userName,
//                   userLastName: widget.userLastName,
//                   userEmail: widget.userEmail,
//                   userContactNum: widget.userContactNum,
//                   userMiddleName: widget.userMiddleName,
//                 ),
//               ));
//             },
//             child: Icon(
//               Icons.assignment_add,
//               color: Colors.white,
//             ),
//             backgroundColor: Colors.grey,
//           ),
//           floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//         ));
//   }
// }

class Setting extends StatelessWidget {
  final String userName;
  final String userLastName;
  final String userEmail;
  String userMiddleName; // Add this if you have a middle name
  String userContactNum; // Add this for contact number

  Setting({
    required this.userName,
    required this.userLastName,
    required this.userEmail,
    required this.userMiddleName, // Optional middle name
    required this.userContactNum, // Optional contact number
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: SideBarLayout(
          title: "Settings",
          mainContent: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0), // Add some padding around the form
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Text(
                    'First Name: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextFormField(
                    readOnly: true,
                    initialValue: userName,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Middle Name: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextFormField(
                    readOnly: true,
                    initialValue: userMiddleName,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Last Name: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextFormField(
                    readOnly: true,
                    initialValue: userLastName,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Contact Number: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextFormField(
                    readOnly: true,
                    initialValue: userContactNum,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Email Address: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextFormField(
                    initialValue: userEmail,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(
                      height:
                          210), // Add space between the text fields and the button
                  Center(
                    child: SizedBox(
                      height: 50,
                      width: 350,
                      child: ElevatedButton(
                        onPressed: () {
                          _logout(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Text(
                          'LOG OUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          userName: userName,
          userLastName: userLastName,
          userEmail: userEmail,
          userContactNum: userContactNum,
          userMiddleName: userMiddleName,
        ));
  }
}

Future<void> _logout(BuildContext context) async {
  try {
    final attendanceModel =
        Provider.of<AttendanceModel>(context, listen: false);
    attendanceModel.reset();

    final prefs = await SharedPreferences.getInstance();

    // Remove all user-specific data
    await prefs.remove('isLoggedIn');
    await prefs.remove('userName');
    await prefs.remove('userMiddleName');
    await prefs.remove('userLastName');
    await prefs.remove('userContactNum');
    await prefs.remove('userEmail');
    await prefs.remove('loadedSKUs');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged out successfully')),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  } catch (e) {
    print('Error logging out: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logout failed. Please try again.')),
    );
  }
}

class SideBarLayout extends StatefulWidget {
  final String title;
  final Widget mainContent;
  final List<Widget>? appBarActions;
  String userName;
  String userLastName;
  String userEmail;
  String userMiddleName;
  String userContactNum;

  SideBarLayout({
    required this.title,
    required this.mainContent,
    this.appBarActions,
    required this.userName,
    required this.userLastName,
    required this.userEmail,
    required this.userContactNum,
    required this.userMiddleName,
  });

  @override
  _SideBarLayoutState createState() => _SideBarLayoutState();
}

class _SideBarLayoutState extends State<SideBarLayout> {
  String userName = '';
  String userLastName = '';
  String userEmail = '';
  String userContactNum = '';
  String userMiddleName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    // userMiddleName =
    //     widget.userMiddleName ?? ''; // Provide a default value if null
  }

  Future<void> _fetchUserInfo() async {
    try {
      final userInfo =
          await MongoDatabase.getUserDetailsByUsername('user_id_here');
      if (userInfo != null) {
        print(userInfo); // Print the retrieved user information
        setState(() {
          widget.userName = userInfo['firstName'] ?? '';
          widget.userMiddleName = userInfo['middleName'] ?? '';
          widget.userLastName = userInfo['lastName'] ?? '';
          widget.userContactNum = userInfo['contactNum'] ?? '';
          widget.userEmail = userInfo['emailAddress'] ?? '';
        });
      } else {
        // Handle case where user info is null
      }
    } catch (e) {
      // Handle error
      print('Error fetching user info: $e');
      // Show a message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: FutureBuilder(
          future: _fetchUserInfo(),
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[900]!,
                        Colors.grey[800]!,
                        Colors.grey[400]!,
                      ],
                    ),
                  ),
                ),
                title: Text(
                  widget.title,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                actions: widget.appBarActions,
              ),
              drawer: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    UserAccountsDrawerHeader(
                      accountName: Text(
                        '${widget.userName} ${widget.userLastName}',
                        style: TextStyle(color: Colors.white),
                      ),
                      accountEmail: Text(
                        widget.userEmail,
                        style: TextStyle(color: Colors.white),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey[900]!,
                            Colors.grey[800]!,
                            Colors.grey[400]!,
                          ],
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.account_circle_outlined,
                      ),
                      title: const Text('Attendance'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => Attendance(
                                    userName: widget.userName,
                                    userLastName: widget.userLastName,
                                    userEmail: widget.userEmail,
                                    userContactNum: widget.userContactNum,
                                    userMiddleName: widget.userMiddleName,
                                  )),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: const Text('Inventory'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => Inventory(
                                    userName: widget.userName,
                                    userLastName: widget.userLastName,
                                    userEmail: widget.userEmail,
                                    userContactNum: widget.userContactNum,
                                    userMiddleName: widget.userMiddleName,
                                  )),
                        );
                      },
                    ),
                    // ListTile(
                    //   leading: const Icon(Icons.assignment_return_outlined),
                    //   title: const Text('Return To Vendor'),
                    //   onTap: () {
                    //     Navigator.of(context).push(
                    //       MaterialPageRoute(
                    //           builder: (context) => RTV(
                    //                 userName: widget.userName,
                    //                 userLastName: widget.userLastName,
                    //                 userEmail: widget.userEmail,
                    //                 userContactNum: widget.userContactNum,
                    //                 userMiddleName: widget.userMiddleName,
                    //               )),
                    //     );
                    //   },
                    // ),
                    const Divider(color: Colors.black),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => Setting(
                                    userName: widget.userName,
                                    userLastName: widget.userLastName,
                                    userEmail: widget.userEmail,
                                    userContactNum: widget.userContactNum,
                                    userMiddleName: widget.userMiddleName,
                                  )),
                        );
                      },
                    ),
                  ],
                ),
              ),
              body: widget.mainContent,
            );
          },
        ));
  }
}

class DateTimeWidget extends StatefulWidget {
  @override
  _DateTimeWidgetState createState() => _DateTimeWidgetState();
}

class _DateTimeWidgetState extends State<DateTimeWidget> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    // Initialize the current time and start the timer to update it periodically
    _currentTime = DateTime.now();
    _timer = Timer.periodic(Duration(seconds: 1), _updateTime);
  }

  @override
  void dispose() {
    // Dispose the timer when the widget is disposed
    _timer.cancel();
    super.dispose();
  }

  void _updateTime(Timer timer) {
    // Update the current time every second
    setState(() {
      _currentTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = DateFormat('h:mm a').format(_currentTime);
    String dayOfWeek = DateFormat('EEEE').format(_currentTime);
    String formattedDate = DateFormat.yMMMMd().format(_currentTime);

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '$formattedDate, $dayOfWeek',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: must_be_immutable, prefer_const_constructors, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, library_private_types_in_public_api, unnecessary_string_interpolations, sort_child_properties_last, avoid_print, use_rethrow_when_possible, depend_on_referenced_packages
import 'dart:convert';

import 'package:demo_app/editInventory_screen.dart';
import 'package:demo_app/editRTV_screen.dart';
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
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:io';

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
          title: "ATTENDANCE",
          mainContent: SingleChildScrollView(
            // Wrap the Column with SingleChildScrollView
            child: Column(
              children: [
                DateTimeWidget(),
                AttendanceWidget(
                    userEmail: userEmail,
                    userFirstName: userName,
                    userLastName: userLastName),
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
  final String userFirstName;
  final String userLastName;

  AttendanceWidget({
    required this.userEmail,
    required this.userFirstName,
    required this.userLastName,
  });
  @override
  _AttendanceWidgetState createState() => _AttendanceWidgetState();
}

class _AttendanceWidgetState extends State<AttendanceWidget> {
  String? timeInLocation = 'No location';
  String? timeOutLocation = 'No location';
  bool _isTimeInLoading = false; // For Time In button loading state
  bool _isTimeOutLoading = false; // For Time Out button loading state
  String? _selectedAccount; // Persisted selected value
  List<String> _branchList = [];
  Map<String, Map<String, dynamic>> _attendanceData = {};
  File? _selfie;
  final picker = ImagePicker();

  Future<void> _pickSelfie() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selfie = File(pickedFile.path);
      });

      // Save the selfie URL (or file path) to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'selfieUrl', pickedFile.path); // Store the path of the image file
    }
  }

  Future<void> _loadSelfieUrl(BuildContext context) async {
    if (_selectedAccount == null) {
      print("No branch selected. Cannot load selfie URL.");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load 'isTimeInRecorded' flag and selfie URL for the selected branch
    bool isRecorded =
        prefs.getBool('isTimeInRecorded_${_selectedAccount!}') ?? false;
    String? storedSelfieUrl = prefs.getString('selfieUrl_${_selectedAccount!}');

    // Update the AttendanceModel
    final attendanceModel =
        Provider.of<AttendanceModel>(context, listen: false);
    attendanceModel.setIsTimeInRecorded(isRecorded);

    if (storedSelfieUrl != null) {
      attendanceModel.setSelfieUrlForBranch(_selectedAccount!, storedSelfieUrl);
      print("Loaded selfie URL for branch $_selectedAccount: $storedSelfieUrl");
    } else {
      print("No selfie URL found for branch $_selectedAccount.");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSelfieUrl(
          context); // Load the selfie URL when the screen is initialized
    });
    _loadSavedBranch();

    // Set loading states to true initially
    _isTimeInLoading = true;
    _isTimeOutLoading = true;

    // Fetch branches and initialize attendance status
    fetchBranches().then((_) {
      // After branches are fetched, initialize the attendance status
      _initializeAttendanceStatus().then((_) {
        // Once the attendance status is initialized, set loading states to false
        setState(() {
          _isTimeInLoading = false;
          _isTimeOutLoading = false;
        });
      }).catchError((error) {
        // Handle any errors that occur during initialization
        print("Error initializing attendance status: $error");
        setState(() {
          _isTimeInLoading = false;
          _isTimeOutLoading =
              false; // Ensure loading states are reset even on error
        });
      });
    }).catchError((error) {
      // Handle any errors that occur during branch fetching
      print("Error fetching branches: $error");
      setState(() {
        _isTimeInLoading = false;
        _isTimeOutLoading =
            false; // Ensure loading states are reset even on error
      });
    });
  }

  Future<void> fetchBranches() async {
    try {
      final db = await mongo.Db.create(INVENTORY_CONN_URL);
      await db.open();
      final collection = db.collection(USER_NEW);
      final List<Map<String, dynamic>> branchDocs = await collection
          .find(mongo.where.eq('emailAddress', widget.userEmail))
          .toList();

      final prefs = await SharedPreferences.getInstance();
      final savedBranch = prefs.getString('selectedBranch');

      setState(() {
        _branchList = branchDocs
            .map((doc) => doc['accountNameBranchManning'])
            .where((branch) => branch != null)
            .expand((branch) => branch is List ? branch : [branch])
            .map((branch) => branch.toString())
            .toList();

        // Use the saved branch if it exists, otherwise fallback to the first branch
        _selectedAccount =
            savedBranch != null && _branchList.contains(savedBranch)
                ? savedBranch
                : (_branchList.isNotEmpty ? _branchList.first : '');
      });

      // Load attendance data for the saved/selected branch
      if (_selectedAccount != null && _attendanceData.isEmpty) {
        await _loadAttendanceLocally(_selectedAccount!);
      }

      await db.close();
    } catch (e) {
      print('Error fetching branch data: $e');
    }
  }

  Future<void> _loadSavedBranch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAccount = prefs.getString('selectedBranch');
    });
  }

  Future<void> _saveSelectedBranch(String branch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedBranch', branch);
  }

  Future<void> _onBranchChanged(String newBranch) async {
    setState(() {
      _selectedAccount = newBranch;
    });
    _loadSelfieUrl(context);
    _saveSelectedBranch(newBranch); // Save the selected branch

    // Reset attendance model
    Provider.of<AttendanceModel>(context, listen: false).reset();

    // Remove cached data for the selected branch to ensure fresh data loads
    _attendanceData.remove(newBranch);

    // Re-initialize attendance status for the selected branch
    await _initializeAttendanceStatus();
  }

  Future<Map<String, dynamic>?> _loadAttendanceLocally(
      String accountNameBranchManning) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = '${widget.userEmail}_${accountNameBranchManning}';
    String? storedData = prefs.getString(key);
    if (storedData != null) {
      return jsonDecode(storedData);
    }
    return null;
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

  Future<void> _initializeAttendanceStatus() async {
    final attendanceModel =
        Provider.of<AttendanceModel>(context, listen: false);
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? currentBranch = _selectedAccount;

    if (currentBranch == null) {
      print("Warning: No selected account found.");
      return;
    }

    Map<String, dynamic>? localData = _attendanceData[currentBranch];

    if (localData != null && localData.isNotEmpty) {
      _updateUIFromLocalData(localData);
    } else {
      var attendanceStatus = await MongoDatabase.getAttendanceStatus(
          widget.userEmail, _selectedAccount!);

      if (attendanceStatus != null && attendanceStatus.isNotEmpty) {
        if (attendanceStatus['accountNameBranchManning'] == currentBranch) {
          List<dynamic> rawLogs = attendanceStatus['timeLogs'];

          Map<String, dynamic>? latestLog;
          if (rawLogs.isNotEmpty) {
            latestLog = rawLogs.reduce((a, b) =>
                DateTime.parse(a['timeIn']).isAfter(DateTime.parse(b['timeIn']))
                    ? a
                    : b);
          }

          if (latestLog != null) {
            Map<String, dynamic> attendanceData = {
              'timeIn': latestLog['timeIn'],
              'timeOut': latestLog['timeOut'],
              'timeInLocation': latestLog['timeInLocation'],
              'timeOutLocation': latestLog['timeOutLocation'],
              'accountNameBranchManning':
                  attendanceStatus['accountNameBranchManning'],
              'isTimeInRecorded': latestLog['timeIn'] != null,
              'isTimeOutRecorded': latestLog['timeOut'] != null,
            };

            _updateUIFromServerData(attendanceData);
            _attendanceData[currentBranch] = attendanceData;
            _saveAttendanceLocally(currentBranch, attendanceData);
          } else {
            _updateUIForNoAttendance();
          }
        } else {
          _updateUIForNoAttendance();
        }
      } else {
        _updateUIForNoAttendance();
      }
    }
  }

  void _updateUIFromLocalData(Map<String, dynamic> localData) {
    setState(() {
      timeInLocation = localData['timeInLocation'] ?? 'No location';
      timeOutLocation = localData['timeOutLocation'] ?? 'No location';
    });

    final attendanceModel =
        Provider.of<AttendanceModel>(context, listen: false);
    attendanceModel.updateTimeIn(localData['timeIn']);
    attendanceModel.updateTimeOut(localData['timeOut']);
    attendanceModel.setIsTimeInRecorded(localData['isTimeInRecorded']);
    attendanceModel.setIsTimeOutRecorded(localData['isTimeOutRecorded']);
  }

  void _updateUIFromServerData(Map<String, dynamic> serverData) {
    setState(() {
      timeInLocation = serverData['timeInLocation'] ?? 'No location';
      timeOutLocation = serverData['timeOutLocation'] ?? 'No location';
    });

    final attendanceModel =
        Provider.of<AttendanceModel>(context, listen: false);

    attendanceModel.updateTimeIn(serverData['timeIn']);
    attendanceModel.updateTimeOut(serverData['timeOut']);
    attendanceModel
        .setIsTimeInRecorded(serverData['isTimeInRecorded'] ?? false);
    attendanceModel
        .setIsTimeOutRecorded(serverData['isTimeOutRecorded'] ?? false);

    if (_selectedAccount != null && serverData.isNotEmpty) {
      _attendanceData[_selectedAccount!] = serverData; // Use '!' for null check
      _saveAttendanceLocally(
          _selectedAccount!, serverData); // Use '!' for null check
    }
  }

  void _updateUIForNoAttendance() {
    final attendanceModel =
        Provider.of<AttendanceModel>(context, listen: false);
    attendanceModel.reset();
    setState(() {
      timeInLocation = 'No location';
      timeOutLocation = 'No location';
    });

    if (_selectedAccount != null) {
      _attendanceData[_selectedAccount!] = {};
      _saveAttendanceLocally(_selectedAccount!, {}); // Use '!' for null check
    }
  }

  void _saveAttendanceLocally(
      String branch, Map<String, dynamic> attendanceData) {
    SharedPreferences.getInstance().then((prefs) {
      String key = '${widget.userEmail}_all_attendance';
      String? storedData = prefs.getString(key);
      Map<String, dynamic> allAttendanceData;

      if (storedData != null) {
        allAttendanceData = jsonDecode(storedData);
      } else {
        allAttendanceData = {};
      }

      if (branch != null && attendanceData.isNotEmpty) {
        allAttendanceData[branch] = attendanceData;
      } else if (branch != null) {
        allAttendanceData.remove(branch);
      }
      prefs.setString(key, jsonEncode(allAttendanceData));
    });
  }

  Future<Map<String, dynamic>> _loadAllAttendanceLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = '${widget.userEmail}_all_attendance';
    String? storedData = prefs.getString(key);

    if (storedData != null) {
      return jsonDecode(storedData);
    }
    return {};
  }

  String? _formatTime(String? time) {
    if (time == null) return 'Not recorded';
    try {
      // Try parsing the time using DateTime.tryParse() for safer error handling
      DateTime dateTime = DateTime.tryParse(time) ??
          DateTime.now(); // Default to current time if parsing fails
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      print('Error formatting time: $e');
      return 'Not recorded';
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
    String currentTimeIn =
        DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());

    Position? position = await _getCurrentLocation();
    String location = 'No location';
    double? latitude;
    double? longitude;

    if (position != null) {
      location = await _getAddressFromLatLong(position);
      latitude = position.latitude;
      longitude = position.longitude;

      setState(() {
        timeInLocation = location;
      });
    }

    // Step 1: Capture and upload selfie
    if (_selfie == null) {
      await _pickSelfie();
    }
    if (_selfie == null) {
      _showSnackbar(context, 'Selfie is required to record Time In');
      return;
    }

    String selfieUrl = '';
    try {
      // Generate the file name using first name, last name, and timestamp
      String fileName =
          '${widget.userFirstName}_${widget.userLastName}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Compress and resize the image (optional step to reduce file size)
      File compressedImage = await _compressImage(_selfie!);

      // Get the pre-signed URL from the backend
      final response = await http.post(
        Uri.parse(
            'https://eb-inventory-backend.onrender.com/save-attendance-images'),
        body: jsonEncode({
          'fileName': fileName, // Pass the generated file name
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate pre-signed URL');
      }

      final uploadUrl = jsonDecode(response.body)['url'];

      // Step 2: Upload selfie to S3
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        body: compressedImage.readAsBytesSync(),
        headers: {'Content-Type': 'image/jpeg'},
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception(
            'Failed to upload selfie. Status Code: ${uploadResponse.statusCode}');
      }

      // Extract the uploaded image URL (this URL doesn't include the query params)
      selfieUrl = uploadUrl.split('?').first;
    } catch (e) {
      _showSnackbar(context, 'Error uploading selfie: $e');
      return;
    }

    // Step 2: Save data to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('timeInLocation', location);
    await prefs.setDouble('timeInLatitude', latitude ?? 0.0);
    await prefs.setDouble('timeInLongitude', longitude ?? 0.0);
    await prefs.setString('timeIn', currentTimeIn); // Save Time In
    await prefs.setBool('isTimeInRecorded_${_selectedAccount}', true);
    await prefs.setString('selfieUrl_${_selectedAccount}', selfieUrl);

    // Step 3: Save Time In to the database
    try {
      var result = await MongoDatabase.logTimeIn(
        widget.userEmail,
        location,
        _selectedAccount ?? '',
        latitude ?? 0.0, // Default to 0.0 if position is null
        longitude ?? 0.0, // Default to 0.0 if position is null
        selfieUrl, // Pass the selfie URL
      );

      if (result == "Success") {
        // Update the attendance model and UI state after successful Time In
        attendanceModel.updateTimeIn(currentTimeIn);
        attendanceModel.setIsTimeInRecorded(true);
        attendanceModel.setSelfieUrlForBranch(_selectedAccount!, selfieUrl);

        _showSnackbar(context, 'Time In recorded successfully');
      } else {
        _showSnackbar(context, 'Failed to record Time In');
      }
    } catch (e) {
      _showSnackbar(context, 'Error recording Time In');
    }
  }

  Future<File> _compressImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(Uint8List.fromList(bytes));

    if (image != null) {
      // Resize the image (optional: adjust the width and height as needed)
      img.Image resizedImage =
          img.copyResize(image, width: 800); // Adjust width to 800px

      // Compress the image to reduce quality (optional: adjust the quality from 0 to 100)
      List<int> compressedBytes =
          img.encodeJpg(resizedImage, quality: 80); // Quality 80 (out of 100)

      // Convert compressed image to File for upload
      File compressedImageFile = File(imageFile.path)
        ..writeAsBytesSync(compressedBytes);
      return compressedImageFile;
    } else {
      throw Exception('Failed to process image');
    }
  }

  void _recordTimeOut(BuildContext context) async {
    final attendanceModel =
        Provider.of<AttendanceModel>(context, listen: false);
    String currentTimeOut =
        DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());

    Position? position = await _getCurrentLocation();
    String location = 'No location';
    double? latitude;
    double? longitude;

    if (position != null) {
      location = await _getAddressFromLatLong(position);
      latitude = position.latitude;
      longitude = position.longitude;

      setState(() {
        timeOutLocation = location;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('timeOutLocation', location);
      await prefs.setDouble('timeOutLatitude', latitude);
      await prefs.setDouble('timeOutLongitude', longitude);
    }

    setState(() {
      _isTimeOutLoading = true; // Start loading
    });

    try {
      var result = await MongoDatabase.logTimeOut(
        widget.userEmail,
        location,
        _selectedAccount ?? '', // Pass the selected branch
        latitude ?? 0.0, // Default to 0.0 if position is null
        longitude ?? 0.0, // Default to 0.0 if position is null
      );
      if (result == "Success") {
        attendanceModel.updateTimeOut(currentTimeOut);
        attendanceModel.setIsTimeOutRecorded(true);
        _showSnackbar(context, 'Time Out recorded successfully');
      } else if (result == "No open time found for today") {
        _showSnackbar(context, 'No open Time In found to log Time Out');
      } else {
        _showSnackbar(context, 'Failed to record Time Out');
      }
    } finally {
      setState(() {
        _isTimeOutLoading = false; // Stop loading
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

  void _viewSelfie(BuildContext context) {
    final attendanceModel =
        Provider.of<AttendanceModel>(context, listen: false);

    // Safely handle null _selectedAccount
    if (_selectedAccount == null) {
      _showSnackbar(context, "Please select a branch first.");
      return;
    }

    final selfieUrl = attendanceModel.getSelfieUrlForBranch(_selectedAccount!);
    print("Retrieved selfie URL for branch $_selectedAccount: $selfieUrl");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Your Time In Picture",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 15),
              selfieUrl != null
                  ? (selfieUrl.startsWith(
                          '/data/user/') // Check if it's a local file path
                      ? Image.file(
                          File(selfieUrl),
                          fit: BoxFit.cover,
                          width: 200,
                          height: 200,
                        )
                      : Image.network(
                          selfieUrl, // Handle network URL if needed
                          fit: BoxFit.cover,
                          width: 200,
                          height: 200,
                        ))
                  : const Text("No photo available."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Consumer<AttendanceModel>(
        builder: (context, attendanceModel, child) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedAccount,
                  items: _branchList.map((branch) {
                    return DropdownMenuItem<String>(
                      value: branch,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        child: Row(
                          children: [
                            Icon(Icons.storefront_outlined,
                                color: Color.fromARGB(255, 26, 20, 71)),
                            SizedBox(width: 8),
                            Text(branch, style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: attendanceModel.isTimeInRecorded &&
                          !attendanceModel.isTimeOutRecorded
                      ? null // Disable if user is clocked in
                      : (value) => _onBranchChanged(value!),
                  decoration: InputDecoration(
                    hintText: 'Select Branch',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 26, 20, 71)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 26, 20, 71), width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a branch';
                    }
                    return null;
                  },
                  disabledHint: Text(_selectedAccount ?? 'Select Branch',
                      style: TextStyle(color: Colors.grey)),
                ),
                SizedBox(height: 20),

                // Time In Container
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromARGB(255, 26, 20, 71).withOpacity(0.8),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "TIME IN",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: !attendanceModel.isTimeInRecorded &&
                                !_isTimeInLoading
                            ? () async {
                                setState(() {
                                  _isTimeInLoading =
                                      true; // Show loading spinner
                                });

                                // Step 1: Capture a selfie
                                await _pickSelfie();

                                if (_selfie == null) {
                                  _showSnackbar(context,
                                      'Selfie is required for Time In');
                                  setState(() {
                                    _isTimeInLoading =
                                        false; // Stop loading spinner
                                  });
                                  return;
                                }

                                // Step 2: Record Time In with selfie
                                await _confirmAndRecordTimeIn(context);

                                setState(() {
                                  _isTimeInLoading =
                                      false; // Stop loading spinner
                                });
                              }
                            : null,
                        style: ButtonStyle(
                          padding:
                              MaterialStateProperty.all<EdgeInsetsGeometry>(
                            const EdgeInsets.symmetric(vertical: 30),
                          ),
                          minimumSize: MaterialStateProperty.all<Size>(
                            const Size(150, 50),
                          ),
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (states) {
                              if (!attendanceModel.isTimeInRecorded) {
                                return Color.fromARGB(255, 26, 20, 71);
                              } else {
                                return Colors.grey;
                              }
                            },
                          ),
                        ),
                        child: _isTimeInLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Time In",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                      ),
                      SizedBox(height: 15),
                      if (attendanceModel.isTimeInRecorded &&
                          _selectedAccount != null &&
                          attendanceModel
                                  .getSelfieUrlForBranch(_selectedAccount!) !=
                              null)
                        ElevatedButton(
                          onPressed: () {
                            _viewSelfie(context); // Function to view the selfie
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 30),
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text(
                            "View Picture",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      SizedBox(height: 15),
                      Text(
                        "Time In: ${_formatTime(attendanceModel.timeIn)}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "Location: $timeInLocation",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Time Out Container
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromARGB(255, 26, 20, 71)
                            .withOpacity(0.8), // Adjust the opacity if needed
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "TIME OUT",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: attendanceModel.isTimeInRecorded &&
                                !attendanceModel.isTimeOutRecorded &&
                                !_isTimeOutLoading
                            ? () => _confirmAndRecordTimeOut(context)
                            : null,
                        style: ButtonStyle(
                          padding:
                              MaterialStateProperty.all<EdgeInsetsGeometry>(
                            const EdgeInsets.symmetric(vertical: 30),
                          ),
                          minimumSize: MaterialStateProperty.all<Size>(
                            const Size(150, 50),
                          ),
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
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
                            ? CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Time Out",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Time Out: ${_formatTime(attendanceModel.timeOut)}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "Location: $timeOutLocation",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                if (attendanceModel.timeIn == null ||
                    _formatTime(attendanceModel.timeIn) == null)
                  Text(
                    'No attendance recorded for this branch.',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
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

  Future<void> _markItemAsDone(String inputId, String userEmail) async {
    try {
      final db = await mongo.Db.create(INVENTORY_CONN_URL);
      await db.open();
      final collection = db.collection(USER_INVENTORY);

      // Update the item to mark it as done
      await collection.update(
        mongo.where.eq('inputId', inputId).eq('userEmail', userEmail),
        mongo.modify.set('isDone', true),
      );

      await db.close();
      print('Item marked as done successfully.');
    } catch (e) {
      print('Error marking item as done: $e');
    }
  }

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
            title: "INVENTORY",
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
                        color: Color.fromRGBO(26, 20, 71, 1),
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

                                      // Function to check if the item should be disabled based on the day of the week and item status
                                      bool _isEditingDisabled(
                                          InventoryItem item) {
                                        DateTime now = DateTime.now();
                                        bool isMondayToThursday = now.weekday >=
                                                DateTime.monday &&
                                            now.weekday <= DateTime.thursday;

                                        // // Disable button if it's Monday to Thursday and the item status is "Carried"
                                        // if (item.status == 'Carried' &&
                                        //     isMondayToThursday) {
                                        //   return true; // Disabled Monday to Thursday for "Carried"
                                        // }

                                        // Disable permanently for "Not Carried" or "Delisted"
                                        return item.status == 'Not Carried' ||
                                            item.status == 'Delisted';
                                      }

                                      // Function to get the color for the button
                                      Color? _getButtonColor(
                                          InventoryItem item) {
                                        if (_isEditingDisabled(item)) {
                                          return Colors.red; // Red for disabled
                                        }
                                        return null; // Default color if enabled
                                      }

                                      // Function to get the onPressed action based on the item status and current day
                                      VoidCallback? _getButtonAction(
                                          InventoryItem item) {
                                        if (_isEditingDisabled(item)) {
                                          return null; // Disable the button if the condition is met
                                        }

                                        return item.status == 'Carried' &&
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
                                                      userEmail:
                                                          widget.userEmail,
                                                      userContactNum:
                                                          widget.userContactNum,
                                                      userLastName:
                                                          widget.userLastName,
                                                      userMiddleName:
                                                          widget.userMiddleName,
                                                      userName: widget.userName,
                                                      onCancel: () async {
                                                        // Reset editing status back to false (not editing anymore)
                                                        await _updateEditingStatus(
                                                            item.inputId,
                                                            widget.userEmail,
                                                            false);
                                                        setState(
                                                            () {}); // Refresh UI after cancel
                                                      },
                                                      onSave: () async {
                                                        hasSavedChanges =
                                                            true; // Indicate that changes have been saved
                                                        await _updateEditingStatus(
                                                            item.inputId,
                                                            widget.userEmail,
                                                            true); // Mark as edited
                                                        setState(
                                                            () {}); // Refresh UI after saving
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
                                            : null; // No action if not "Carried" or isEditing is true
                                      }

                                      return ListTile(
                                        title: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(item.week),
                                            if (item.status == 'Carried' &&
                                                !item
                                                    .isDone) // ✅ Show Icon if Carried & Not Done
                                              IconButton(
                                                icon: Icon(Icons.edit),
                                                color: _getButtonColor(item) ??
                                                    Color.fromRGBO(
                                                        26, 20, 71, 1),
                                                onPressed: () async {
                                                  await _updateEditingStatus(
                                                      item.inputId,
                                                      widget.userEmail,
                                                      false);

                                                  bool hasSavedChanges = false;
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditInventoryScreen(
                                                        inventoryItem: item,
                                                        userEmail:
                                                            widget.userEmail,
                                                        userContactNum: widget
                                                            .userContactNum,
                                                        userLastName:
                                                            widget.userLastName,
                                                        userMiddleName: widget
                                                            .userMiddleName,
                                                        userName:
                                                            widget.userName,
                                                        onCancel: () async {
                                                          await _updateEditingStatus(
                                                              item.inputId,
                                                              widget.userEmail,
                                                              false);
                                                          setState(() {});
                                                        },
                                                        onSave: () async {
                                                          hasSavedChanges =
                                                              true;
                                                          await _updateEditingStatus(
                                                              item.inputId,
                                                              widget.userEmail,
                                                              true);

                                                          // ✅ Mark item as done after saving changes
                                                          await _markItemAsDone(
                                                              item.inputId,
                                                              widget.userEmail);

                                                          setState(() {});
                                                        },
                                                      ),
                                                    ),
                                                  );

                                                  if (hasSavedChanges) {
                                                    await _updateEditingStatus(
                                                        item.inputId,
                                                        widget.userEmail,
                                                        true);
                                                  }

                                                  setState(() {});
                                                },
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
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Date: ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.date}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
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
                                                          'Inventory Number: ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.inputId}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Merchandiser: ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.name}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Outlet: ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${item.accountNameBranchManning}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
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
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.period}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
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
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.month}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
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
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.week}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // SizedBox(height: 10),
                                              // Text.rich(
                                              //   TextSpan(
                                              //     children: [
                                              //       TextSpan(
                                              //         text: 'Category: ',
                                              //         style: TextStyle(
                                              //             color: Colors.black),
                                              //       ),
                                              //       TextSpan(
                                              //         text: '${item.category}',
                                              //         style: TextStyle(
                                              //           fontWeight:
                                              //               FontWeight.bold,
                                              //           color: Colors.black,
                                              //         ),
                                              //       ),
                                              //     ],
                                              //   ),
                                              // ),
                                              SizedBox(height: 10),
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'SKU: ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${item.skuDescription}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // SizedBox(height: 10),
                                              // Text.rich(
                                              //   TextSpan(
                                              //     children: [
                                              //       TextSpan(
                                              //         text: 'Products: ',
                                              //         style: TextStyle(
                                              //             color: Colors.black),
                                              //       ),
                                              //       TextSpan(
                                              //         text: '${item.products}',
                                              //         style: TextStyle(
                                              //           fontWeight:
                                              //               FontWeight.bold,
                                              //           color: Colors.black,
                                              //         ),
                                              //       ),
                                              //     ],
                                              //   ),
                                              // ),
                                              SizedBox(height: 10),
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: '4-Pack BarCode: ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.skuCode}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
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
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.status}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
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
                                                          'Beginning (Selling Area): ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${item.beginningSA}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
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
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${item.beginningWA}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
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
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.endingSA}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
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
                                                          'Ending (Warehouse Area): ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.endingWA}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Beginning: ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.beginning}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Delivery: ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.delivery}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Ending: ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.ending}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
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
                                                      Text.rich(
                                                        TextSpan(
                                                          children: [
                                                            TextSpan(
                                                              text:
                                                                  'Expiry Date: ',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black),
                                                            ),
                                                            TextSpan(
                                                              text:
                                                                  '${expiry['expiryMonth']}',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Text.rich(
                                                        TextSpan(
                                                          children: [
                                                            TextSpan(
                                                              text:
                                                                  'Quantity: ',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black),
                                                            ),
                                                            TextSpan(
                                                              text:
                                                                  '${expiry['expiryPcs']}',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(height: 10),
                                                      if (expiry.containsKey(
                                                          'manualPcsInput'))
                                                        Text.rich(
                                                          TextSpan(
                                                            children: [
                                                              TextSpan(
                                                                text:
                                                                    'Manual PCS Input: ',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black),
                                                              ),
                                                              TextSpan(
                                                                text:
                                                                    '${expiry['manualPcsInput']}',
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Offtake: ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.offtake}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
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
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${item.inventoryDaysLevel}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
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
                                                          'Number of Days OOS: ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${item.noOfDaysOOS}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Remarks: ',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${item.remarksOOS}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
            backgroundColor: Color.fromARGB(255, 26, 20, 71),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ));
  }
}

class RTV extends StatefulWidget {
  final String userName;
  final String userLastName;
  final String userEmail;
  String userMiddleName;
  String userContactNum;

  RTV({
    required this.userName,
    required this.userLastName,
    required this.userEmail,
    required this.userContactNum,
    required this.userMiddleName,
  });

  @override
  _RTVState createState() => _RTVState();
}

class _RTVState extends State<RTV> {
  late Future<List<ReturnToVendor>> _futureRTV;
  bool _sortByLatest = true; // Default to sorting by latest date

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _futureRTV = _fetchRTVData();
    });
  }

  Future<List<ReturnToVendor>> _fetchRTVData() async {
    try {
      final db = await mongo.Db.create(MONGO_CONN_URL);
      await db.open();
      final collection = db.collection(USER_RTV);

      final List<Map<String, dynamic>> results =
          await collection.find({'userEmail': widget.userEmail}).toList();

      await db.close();

      List<ReturnToVendor> rtvItems =
          results.map((data) => ReturnToVendor.fromJson(data)).toList();

// Inside your _fetchRTVData method:
      rtvItems.sort((a, b) {
        int dateComparison = b.date.compareTo(a.date);

        if (dateComparison != 0) {
          return dateComparison; // Sort by latest to oldest date
        } else {
          // If dates are the same, sort by the timestamp of ObjectId
          return b.id.dateTime.compareTo(a.id
              .dateTime); // Extracts DateTime from ObjectId for secondary sorting
        }
      });

      return rtvItems;
    } catch (e) {
      print('Error fetching RTV data: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          body: SideBarLayout(
            title: "RTV",
            mainContent: RefreshIndicator(
              onRefresh: () async {
                _fetchData();
              },
              child: FutureBuilder<List<ReturnToVendor>>(
                  future: _futureRTV,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 26, 20, 71),
                        backgroundColor: Colors.transparent,
                      ));
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    } else {
                      List<ReturnToVendor> rtvItems = snapshot.data ?? [];
                      if (rtvItems.isEmpty) {
                        return Center(
                          child: Text(
                            'No RTV created',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black),
                          ),
                        );
                      } else {
                        return ListView.builder(
                            itemCount: rtvItems.length,
                            itemBuilder: (context, index) {
                              ReturnToVendor item = rtvItems[index];

                              return ListTile(
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${item.date}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                      // isEditable
                                      //     ? IconButton(
                                      //         icon: Icon(Icons.edit_document,
                                      //             color: Colors.black),
                                      //         onPressed: () {
                                      //           Navigator.of(context).push(
                                      //             MaterialPageRoute(
                                      //               builder: (context) =>
                                      //                   EditRTVScreen(
                                      //                       item: item),
                                      //             ),
                                      //           );
                                      //         },
                                      //       )
                                      //     : IconButton(
                                      //         icon: Icon(Icons.edit_document,
                                      //             color: Colors.grey),
                                      //         onPressed: null,
                                      //       ),
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
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'RTV Number: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item.inputId,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Date: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item.date,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Outlet: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item.outlet,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'SKU: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item.item,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'EXPIRY DATE: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item.expiryDate,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Amount: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item.amount % 1 == 0
                                                    ? item.amount.toStringAsFixed(
                                                        0) // No decimal if whole number
                                                    : item.amount.toStringAsFixed(
                                                        2), // Show 2 decimals otherwise
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Quantity: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item.quantity % 1 == 0
                                                    ? item.quantity.toStringAsFixed(
                                                        0) // No decimal if whole number
                                                    : item.quantity.toStringAsFixed(
                                                        2), // Show 2 decimals otherwise
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Total: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item.total.toString(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Reason: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item.reason,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Remarks: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item.remarks,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ));
                            });
                      }
                    }
                  }),
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
                    _fetchData();
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
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ReturnVendor(
                  userName: widget.userName,
                  userLastName: widget.userLastName,
                  userEmail: widget.userEmail,
                  userContactNum: widget.userContactNum,
                  userMiddleName: widget.userMiddleName,
                ),
              ));
            },
            child: Icon(
              Icons.assignment_add,
              color: Colors.white,
            ),
            backgroundColor: Color.fromARGB(255, 26, 20, 71),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ));
  }
}

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
                          backgroundColor: Color.fromARGB(255, 26, 20, 71),
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

// Helper function to capitalize the first letter
String _capitalizeFirstLetter(String text) {
  if (text.isEmpty) {
    return text;
  }
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
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
                        Color.fromARGB(255, 26, 20, 71),
                        Color.fromARGB(255, 26, 20, 71),
                        Color.fromARGB(255, 255, 196, 0)!,
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
                      currentAccountPicture: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.account_circle, // Use the desired icon here
                          size: 73.0, // Adjust the size of the icon
                          color: Color.fromARGB(255, 26, 20,
                              71), // Change the icon color if needed
                        ),
                        radius: 40.0, // Adjust the size of the image
                      ),
                      accountName: Padding(
                        padding: const EdgeInsets.only(
                            top:
                                2.0), // Reduce the space between the icon and the name
                        child: Text(
                          '${_capitalizeFirstLetter(widget.userName)} ${_capitalizeFirstLetter(widget.userLastName)}', // Capitalize first letter of first name and last name
                          style: TextStyle(
                            color: Colors.white, // Text color
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0, // Adjust the font size as needed
                          ),
                        ),
                      ),
                      accountEmail: null, // Remove the email
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 26, 20, 71),
                            Color.fromARGB(255, 33, 26, 87),
                            Color.fromARGB(255, 255, 196, 0)!,
                          ],
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.account_box_outlined,
                        color: Color.fromARGB(255, 26, 20, 71),
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
                      leading: Icon(
                        Icons.inventory_2_outlined,
                        color: Color.fromARGB(
                            255, 26, 20, 71), // Replace with your desired color
                      ),
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
                    ListTile(
                      leading: const Icon(
                        Icons.assignment_return_outlined,
                        color: Color.fromARGB(255, 26, 20, 71),
                      ),
                      title: const Text('Return To Vendor'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => RTV(
                                    userName: widget.userName,
                                    userLastName: widget.userLastName,
                                    userEmail: widget.userEmail,
                                    userContactNum: widget.userContactNum,
                                    userMiddleName: widget.userMiddleName,
                                  )),
                        );
                      },
                    ),
                    const Divider(color: Colors.black),
                    ListTile(
                      leading: const Icon(
                        Icons.settings_outlined,
                        color: Color.fromARGB(255, 26, 20, 71),
                      ),
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

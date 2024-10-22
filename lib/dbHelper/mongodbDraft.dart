// ignore_for_file: depend_on_referenced_packages
import 'package:mongo_dart/mongo_dart.dart' as M;
import 'dart:convert';
import 'dart:ffi';
import 'package:demo_app/dbHelper/constant.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:bcrypt/bcrypt.dart';

MongoDemo welcomeFromJson(String str) => MongoDemo.fromJson(json.decode(str));

String welcomeToJson(MongoDemo data) => json.encode(data.toJson());

class MongoDemo {
  final M.ObjectId id;
  String remarks;
  String firstName;
  String middleName;
  String lastName;
  String emailAddress;
  String contactNum;
  String username;
  String password;
  String accountNameBranchManning;
  bool isActivate;
  int type;
  DateTime? timeOut; // Nullable DateTime

  MongoDemo({
    required this.remarks,
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.emailAddress,
    required this.contactNum,
    required this.username,
    required this.password,
    required this.accountNameBranchManning,
    required this.isActivate,
    required this.type,
    this.timeOut,
  });

  factory MongoDemo.fromJson(Map<String, dynamic> json) {
    return MongoDemo(
      id: json['_id'],
      remarks: json['remarks'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      emailAddress: json['emailAddress'],
      contactNum: json['contactNum'],
      username: json['username'],
      password: json['password'],
      accountNameBranchManning: json['accountNameBranchManning'],
      isActivate: json['isActivate'],
      type: json['type'],
      timeOut:
          json['timeOut'] != null ? DateTime.tryParse(json['timeOut']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'remarks': remarks,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'emailAddress': emailAddress,
        'contactNum': contactNum,
        'username': username,
        'password': password,
        'accountNameBranchManning': accountNameBranchManning,
        'isActivate': isActivate,
        'type': type,
        'timeOut': timeOut?.toIso8601String(), // Convert to string if not null
      };
}

Future<String> hashPassword(String password) async {
  // Generate a random salt for each password
  const rounds =
      8; // Adjust the number of rounds based on security requirements
  final salt = BCrypt.gensalt(logRounds: rounds);

  // Hash the password with the generated salt
  final hashedPassword = BCrypt.hashpw(password, salt);
  return hashedPassword;
}

class TimeLog {
  ObjectId id;
  String userEmail;
  DateTime timeIn;
  DateTime? timeOut; // Nullable DateTime
  String? timeInLocation; // Nullable location for time in
  String? timeOutLocation; // Nullable location for time out

  TimeLog({
    required this.id,
    required this.userEmail,
    required this.timeIn,
    this.timeOut,
    required String date,
    this.timeInLocation,
    this.timeOutLocation,
  });

  factory TimeLog.fromJson(Map<String, dynamic> json) => TimeLog(
        id: json['_id'] ?? ObjectId(),
        userEmail: json['userEmail'] ?? '',
        timeIn: DateTime.parse(json['timeIn']),
        timeOut:
            json['timeOut'] != null ? DateTime.tryParse(json['timeOut']) : null,
        date: '',
        timeInLocation: json['timeInLocation'],
        timeOutLocation: json['timeOutLocation'],
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userEmail': userEmail,
        'timeIn': timeIn.toIso8601String(),
        'timeOut': timeOut?.toIso8601String(), // Convert to string if not null
        'timeInLocation': timeInLocation,
        'timeOutLocation': timeOutLocation,
      };
}

// // // INVENTORY DATABASE // // //

class InventoryItem {
  ObjectId id;
  String userEmail;
  String date;
  String inputId;
  String name;
  String accountNameBranchManning;
  String period;
  String month;
  String week;
  String category;
  String skuDescription;
  String products;
  String skuCode;
  String status; // Carried, Not Carried, Delisted
  String remarksOOS;
  String reasonOOS;
  dynamic beginningSA;
  dynamic beginningWA;
  dynamic beginning;
  dynamic delivery;
  dynamic ending;
  dynamic endingSA;
  dynamic endingWA;
  dynamic offtake;
  final double inventoryDaysLevel;
  dynamic noOfDaysOOS;
  final List<Map<String, dynamic>> expiryFields;
  final bool isEditing; // New field

  InventoryItem({
    required this.id,
    required this.userEmail,
    required this.date,
    required this.inputId,
    required this.name,
    required this.accountNameBranchManning,
    required this.period,
    required this.month,
    required this.week,
    required this.category,
    required this.skuDescription,
    required this.products,
    required this.skuCode,
    required this.status,
    required this.beginning,
    required this.beginningSA,
    required this.beginningWA,
    required this.delivery,
    required this.ending,
    required this.endingSA,
    required this.endingWA,
    required this.offtake,
    required this.inventoryDaysLevel,
    required this.noOfDaysOOS,
    required this.expiryFields,
    required this.remarksOOS,
    required this.reasonOOS,
    required this.isEditing,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['_id'] ?? ObjectId(),
        userEmail: json['userEmail'] ?? '',
        date: json['date'] ?? '',
        inputId: json['inputId'] ?? '',
        name: json['name'] ?? '',
        accountNameBranchManning: json['accountNameBranchManning'] ?? '',
        period: json['period'] ?? '',
        month: json['month'] ?? '',
        week: json['week'] ?? '',
        category: json['category'] ?? '',
        skuDescription: json['skuDescription'] ?? '',
        products: json['products'] ?? '',
        skuCode: json['skuCode'] ?? '',
        status: json['status'] ?? '',
        beginning: json['beginning'] ?? 0,
        beginningSA: json['beginningSA'] ?? 0,
        beginningWA: json['beginningWA'] ?? 0,
        delivery: json['delivery'] ?? 0,
        ending: json['ending'] ?? 0,
        endingSA: json['endingSA'] ?? 0,
        endingWA: json['endingWA'] ?? 0,
        offtake: json['offtake'] ?? 0,
        inventoryDaysLevel: (json['inventoryDaysLevel'] != null)
            ? double.parse(json['inventoryDaysLevel'].toStringAsFixed(2))
            : 0.0, // Default value if null
        noOfDaysOOS: json['noOfDaysOOS'] ?? 0,
        expiryFields: (json['expiryFields'] as List<dynamic>?)
                ?.map((item) => item as Map<String, dynamic>)
                .toList() ??
            [], // Ensure expiryFields is not null
        remarksOOS: json['remarksOOS'] ?? '',
        reasonOOS: json['reasonOOS'] ?? '',
        isEditing: json['isEditing'] ?? false, // Default value if null
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userEmail': userEmail,
        'date': date,
        'inputId': inputId,
        'name': name,
        'accountNameBranchManning': accountNameBranchManning,
        'period': period,
        'month': month,
        'week': week,
        'category': category,
        'skuDescription': skuDescription,
        'products': products,
        'skuCode': skuCode,
        'status': status,
        'beginning': beginning,
        'beginningSA': beginningSA,
        'beginningWA': beginningWA,
        'delivery': delivery,
        'ending': ending,
        'endingSA': endingSA,
        'endingWA': endingWA,
        'offtake': offtake,
        'inventoryDaysLevel': inventoryDaysLevel,
        'noOfDaysOOS': noOfDaysOOS,
        'expiryFields': expiryFields,
        'remarksOOS': remarksOOS,
        'reasonOOS': reasonOOS,
        'isEditing': isEditing, // Include in JSON
      };
  void _saveToDatabase(InventoryItem newItem) async {
    // Connect to your MongoDB database
    final db = Db(MONGO_CONN_URL);
    await db.open();

    // Get a reference to the collection where you want to save items
    final collection = db.collection(USER_INVENTORY);

    // Convert the InventoryItem to a Map using the toJson() method
    final Map<String, dynamic> itemMap = newItem.toJson();

    // Insert the item into the collection
    try {
      await collection.insert(itemMap);
      print('Item saved to database');
    } catch (e) {
      // Handle any errors that occur during saving
      print('Error saving item: $e');
    }

    // Close the database connection when done
    await db.close();
  }
}

// class ReturnToVendor {
//   ObjectId id;
//   String inputId;
//   String userEmail;
//   String date;
//   String merchandiserName;
//   String outlet;
//   String category;
//   String item;
//   String quantity;
//   String driverName;
//   String plateNumber;
//   String pullOutReason;

//   ReturnToVendor({
//     required this.inputId,
//     required this.id,
//     required this.userEmail,
//     required this.date,
//     required this.merchandiserName,
//     required this.outlet,
//     required this.category,
//     required this.item,
//     required this.quantity,
//     required this.driverName,
//     required this.plateNumber,
//     required this.pullOutReason,
//   });

//   factory ReturnToVendor.fromJson(Map<String, dynamic> json) => ReturnToVendor(
//         id: json['_id'] ?? ObjectId(),
//         inputId: json['inputId'] ?? '',
//         userEmail: json['userEmail'] ?? '',
//         date: json['date'] ?? '',
//         merchandiserName: json['merchandiserName'] ?? '',
//         outlet: json['outlet'] ?? '',
//         category: json['category'] ?? '',
//         item: json['item'] ?? '',
//         quantity: json['quantity'] ?? '',
//         driverName: json['driverName'] ?? '',
//         plateNumber: json['plateNumber'] ?? '',
//         pullOutReason: json['pullOutReason'] ?? '',
//       );

//   Map<String, dynamic> toJson() => {
//         '_id': id,
//         "inputId": inputId,
//         'userEmail': userEmail,
//         'date': date,
//         'merchandiserName': merchandiserName,
//         'outlet': outlet,
//         'category': category,
//         'Item': item,
//         'quantity': quantity,
//         'driverName': driverName,
//         'plateNumber': plateNumber,
//         'pullOutReason': pullOutReason,
//       };

//   void saveToDatabase(ReturnToVendor newItem) async {
//     final db = Db(MONGO_CONN_URL);
//     await db.open();

//     final collection = db.collection(USER_RTV);

//     final Map<String, dynamic> itemMap = newItem.toJson();

//     try {
//       await collection.insert(itemMap);
//       print('Return to vendor saved to database');
//     } catch (e) {
//       print('Error saving return to vendor: $e');
//     }

//     await db.close();
//   }
// }

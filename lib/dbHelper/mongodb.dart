// ignore_for_file: avoid_print

import 'dart:developer';
import 'package:demo_app/dbHelper/constant.dart';
import 'package:demo_app/dbHelper/mongodbDraft.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  static var db, userCollection;

  static Future<void> connect() async {
    db = await Db.create(MONGO_CONN_URL);
    await db.open();
    inspect(db);
    userCollection = db.collection(USER_NEW);
  }

  static Future<void> close() async {
    if (db != null && db.isConnected) {
      await db.close();
    }
  }

  static Future<String> insert(MongoDemo data) async {
    try {
      if (db == null || !db.isConnected) {
        await connect();
      }
      var userCollection = db.collection(USER_NEW);
      print('Inserting data: ${data.toJson()}');
      await userCollection.insertOne(data.toJson());
      return "Success";
    } catch (e) {
      print("Insertion failed: $e");
      return "Error: $e";
    } finally {
      await close();
    }
  }

  static Future<List<Map<String, dynamic>>> getData() async {
    await connect();
    final arrdata = await userCollection.find().toList();
    await close();
    return arrdata;
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      await connect(); // Ensure connection is established
      if (db.state == State.OPEN) {
        final userData = await userCollection.findOne();
        print('User Data: $userData'); // Print user data for debugging
        return userData;
      } else {
        print('Error: Database connection not open');
        return null;
      }
    } catch (e) {
      print('Error fetching user info: $e');
      return null;
    } finally {
      if (db != null && db.state == State.OPEN) {
        await db.close(); // Close the database connection if it's open
      }
    }
  }

  static Future<Map<String, dynamic>?> getUserDetailsById(String userId) async {
    try {
      await connect(); // Ensure connection is established
      final user =
          await userCollection.findOne({'_id': ObjectId.parse(userId)});
      return user;
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserDetailsByUsername(
      String username) async {
    try {
      await connect(); // Ensure connection is established
      final user = await userCollection.findOne({'username': username});
      return user;
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getBranchData() async {
    try {
      var db = await Db.create(MONGO_CONN_URL);
      await db.open();
      var collection =
          db.collection(USER_NEW); // Ensure this is the correct collection
      var branches = await collection.find().toList();
      await db.close();
      return branches;
    } catch (e) {
      print("Error fetching branch data: $e");
      return [];
    }
  }

  // static Future<void> updateItemInDatabase(ReturnToVendor updatedItem) async {
  //   if (db == null || !db!.isConnected) {
  //     await connect();
  //   }

  //   final collection = db!.collection(USER_RTV);

  //   final Map<String, dynamic> itemMap = updatedItem.toJson();

  //   try {
  //     // Use the ObjectId to identify the document to update
  //     final result = await collection.updateOne(
  //       where.eq('_id', updatedItem.id),
  //       modify
  //           .set('inputId', updatedItem.inputId)
  //           .set('userEmail', updatedItem.userEmail)
  //           .set('date', updatedItem.date)
  //           .set('merchandiserName', updatedItem.merchandiserName)
  //           .set('outlet', updatedItem.outlet)
  //           //.set('category', updatedItem.category)
  //           .set('item', updatedItem.item)
  //           .set('quantity', updatedItem.quantity)
  //           .set('driverName', updatedItem.driverName)
  //           .set('plateNumber', updatedItem.plateNumber)
  //           .set('pullOutReason', updatedItem.pullOutReason),
  //     );

  //     // Check if the update was acknowledged and if any documents were matched or modified
  //     if (result.isAcknowledged) {
  //       if (result.writeErrors.isEmpty) {
  //         print('Return to vendor updated in database');
  //       } else {
  //         print('Errors occurred during update: ${result.writeErrors}');
  //       }
  //     } else {
  //       print('Update not acknowledged');
  //     }
  //   } catch (e) {
  //     print('Error updating return to vendor: $e');
  //   } finally {
  //     await close();
  //   }
  // }

  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      if (db == null || !db.isConnected) {
        await connect();
      }

      final collection = db.collection(USER_INVENTORY);

      final result = await collection.updateOne(
          where.eq('_id', item.id), // Find the document by ID
          modify
              .set('date', item.date)
              .set('inputId', item.inputId)
              .set('name', item.name)
              .set('accountNameBranchManning', item.accountNameBranchManning)
              .set('period', item.period)
              .set('month', item.month)
              .set('week', item.week)
              //.set('category', item.category)
              .set('skuDescription', item.skuDescription)
              //.set('products', item.products)
              .set('skuCode', item.skuCode)
              .set('status', item.status)
              .set('beginning', item.beginning)
              .set('delivery', item.delivery)
              .set('ending', item.ending)
              .set('offtake', item.offtake)
              .set('inventoryDaysLevel', item.inventoryDaysLevel)
              .set('noOfDaysOOS', item.noOfDaysOOS)
              .set('expiryFields', item.expiryFields)
              .set('remarksOOS', item.remarksOOS)
          //.set('reasonOOS', item.reasonOOS),
          );

      if (result.isAcknowledged) {
        print('Inventory item updated in database');
      } else {
        print('Update not acknowledged');
      }
    } catch (e) {
      print('Error updating inventory item: $e');
    } finally {
      await close();
    }
  }

  static Future<String> logTimeIn(
    String userEmail,
    String timeInLocation,
    String accountNameBranchManning,
    double timeInLatitude,
    double timeInLongitude,
    String selfieUrl, // Selfie URL parameter
  ) async {
    try {
      await connect();
      var timeLogCollection = db.collection(USER_ATTENDANCE);
      var todayDate =
          DateTime.now().toLocal().toIso8601String().substring(0, 10);

      // Check if there is an open timeLog entry for today in the selected branch
      var existingRecord = await timeLogCollection.findOne(
        where
            .eq('userEmail', userEmail)
            .and(where.eq('date', todayDate))
            .and(where.eq('accountNameBranchManning', accountNameBranchManning))
            .and(where.eq('timeLogs.timeOut', null)),
      );

      if (existingRecord == null) {
        // No open log exists for this branch today; create a new entry
        var newLog = {
          '_id': ObjectId(),
          'userEmail': userEmail,
          'date': todayDate,
          'accountNameBranchManning': accountNameBranchManning,
          'timeLogs': [
            {
              'timeIn': DateTime.now().toIso8601String(),
              'timeOut': null,
              'timeInLocation': timeInLocation,
              'timeOutLocation': null,
              'time_in_coordinates': {
                'latitude': timeInLatitude,
                'longitude': timeInLongitude,
              },
              'time_out_coordinates': null,
              'selfieUrl': selfieUrl, // Include selfie URL in the log
            }
          ]
        };
        await timeLogCollection.insert(newLog);
        return "Success";
      } else {
        return "Already checked in today for this branch";
      }
    } catch (e) {
      print('Error logging time in: $e');
      return "Error";
    } finally {
      await close();
    }
  }

  static Future<String> logTimeOut(
      String userEmail,
      String timeOutLocation,
      String accountNameBranchManning,
      double timeOutLatitude,
      double timeOutLongitude) async {
    try {
      await connect();
      var timeLogCollection = db.collection(USER_ATTENDANCE);
      var todayDate =
          DateTime.now().toLocal().toIso8601String().substring(0, 10);
      var currentTime = DateTime.now().toIso8601String();

      // Update only the latest open time-log for the user and branch on today's date
      var updates = modify
          .set('timeLogs.\$.timeOut', currentTime)
          .set('timeLogs.\$.timeOutLocation', timeOutLocation)
          .set('timeLogs.\$.time_out_coordinates', {
        'latitude': timeOutLatitude,
        'longitude': timeOutLongitude,
      });

      var result = await timeLogCollection.updateOne(
        where
            .eq('userEmail', userEmail)
            .and(where.eq('date', todayDate))
            .and(where.eq('accountNameBranchManning', accountNameBranchManning))
            .and(where.eq('timeLogs.timeOut', null)),
        updates,
      );

      print('Update Result: $result');

      if (result.isAcknowledged &&
          result.nModified != null &&
          result.nModified > 0) {
        return "Success";
      } else {
        return "No open time-in found for today in this branch";
      }
    } catch (e) {
      print('Error logging time out: $e');
      return "Error";
    } finally {
      await close();
    }
  }

  static Future<Map<String, dynamic>?> getAttendanceStatus(
      String userEmail, String accountNameBranchManning) async {
    try {
      await connect();
      var timeLogCollection = db.collection(USER_ATTENDANCE);
      var todayDate =
          DateTime.now().toLocal().toIso8601String().substring(0, 10);

      var record = await timeLogCollection.findOne(
        where.eq('userEmail', userEmail).and(where.eq('date', todayDate)).and(
            where.eq('accountNameBranchManning', accountNameBranchManning)),
      );

      if (record != null) {
        var attendanceInfo = {
          'accountNameBranchManning': record['accountNameBranchManning'],
          'timeLogs': record['timeLogs'],
        };
        return attendanceInfo;
      }

      return null;
    } catch (e) {
      print('Error fetching attendance status: $e');
      return null;
    } finally {
      await close();
    }
  }

  static Future<String> updateEditingStatus(
      String inputId, String userEmail, bool isEditing) async {
    try {
      await connect();
      final collection = db.collection(USER_INVENTORY);
      final result = await collection.updateOne(
        where.eq('inputId', inputId).and(where.eq('userEmail', userEmail)),
        modify.set('isEditing', isEditing),
      );

      if (result.isAcknowledged && result.nModified == 1) {
        return "Editing status updated successfully";
      } else {
        return "Failed to update editing status";
      }
    } catch (e) {
      print('Error updating editing status: $e');
      return "Error: $e";
    } finally {
      await close();
    }
  }

  static Future<bool> getEditingStatus(String inputId, String userEmail) async {
    try {
      await connect();

      final collection =
          db.collection(USER_INVENTORY); // Collection for ReturnToVendor

      final record = await collection.findOne(
        where.eq('inputId', inputId).and(where.eq('userEmail', userEmail)),
      );

      if (record != null && record.containsKey('isEditing')) {
        return record['isEditing'] as bool;
      } else {
        return false; // Default to false if no status is found
      }
    } catch (e) {
      print('Error fetching editing status: $e');
      return false;
    } finally {
      await close();
    }
  }

  Future<void> _markItemAsDone(String inputId) async {
    final collection = db.collection(
        USER_INVENTORY); // Make sure this matches your collection name

    try {
      await collection.updateOne(
        where.eq('inputId', inputId), // Match the item by inputId
        modify.set('isDone', true), // Set isDone to true
      );
      print('Item marked as done successfully!');
    } catch (e) {
      print('Error marking item as done: $e');
    }
  }

  // static Future<List<Map<String, dynamic>>> getSkusByBranchAndCategory(
  //     String branchName, String category) async {
  //   try {
  //     await connect(); // Ensure the database connection is established

  //     var collection = db.collection(
  //         USER_SKU); // Make sure this points to your 'branchskus' collection

  //     // Query to filter by branch name and category
  //     var result = await collection.find({
  //       'accountNameBranchManning': branchName,
  //       'category': category,
  //       'version': {
  //         '\$in': ['V1', 'V2', 'V3']
  //       }, // Include versions if necessary
  //     }).toList();

  //     // Extract SKUs array from the result
  //     List<Map<String, dynamic>> skus = [];
  //     for (var doc in result) {
  //       if (doc.containsKey('SKUs')) {
  //         skus.addAll(List<Map<String, dynamic>>.from(doc['SKUs']));
  //       }
  //     }

  //     return skus; // Return the SKUs array
  //   } catch (e) {
  //     print('Error retrieving SKUs by branch and category: $e');
  //     return [];
  //   } finally {
  //     await close(); // Ensure the connection is closed after the operation
  //   }
  // }

  // // Function to get saved SKUs for a specific branch
  // static Future<List<String>> getSavedSkusForBranch(String branch) async {
  //   try {
  //     await connect(); // Ensure the database connection is established

  //     var collection = db.collection('branchskus'); // 'branchskus' collection

  //     // Query to filter by branch name and retrieve the saved SKUs
  //     var result = await collection.findOne({
  //       'accountNameBranchManning': branch, // Field that identifies the branch
  //     });

  //     // Extract the SKUs field (assuming it's an array of strings)
  //     if (result != null && result.containsKey('SKUs')) {
  //       List<String> savedSkus = List<String>.from(result['SKUs']);
  //       return savedSkus; // Return the SKUs array
  //     } else {
  //       return []; // Return an empty list if no SKUs found
  //     }
  //   } catch (e) {
  //     print('Error retrieving saved SKUs for branch: $e');
  //     return [];
  //   } finally {
  //     await close(); // Ensure the connection is closed after the operation
  //   }
  // }
}

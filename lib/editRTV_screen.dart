// // ignore_for_file: prefer_final_fields

// import 'package:demo_app/dbHelper/mongodb.dart';
// import 'package:demo_app/dbHelper/mongodbDraft.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class EditRTVScreen extends StatefulWidget {
//   final ReturnToVendor item;

//   const EditRTVScreen({required this.item});

//   @override
//   _EditRTVScreenState createState() => _EditRTVScreenState();
// }

// class _EditRTVScreenState extends State<EditRTVScreen> {
//   final _formKey = GlobalKey<FormState>();

//   late TextEditingController _inputId;
//   late TextEditingController _merchandiserNameController;
//   late TextEditingController _outletController;
//   late TextEditingController _categoryController;
//   late TextEditingController _itemController;
//   late TextEditingController _quantityController;
//   late TextEditingController _driverNameController;
//   late TextEditingController _plateNumberController;
//   late TextEditingController _pullOutReasonController;

//   String selectedCategory = '';
//   List<String> itemOptions = [];
//   String selectedItem = '';
//   bool isSaveButtonEnabled = false;

//   Map<String, List<String>> _categoryToSkuDescriptions = {
//     'Variant': [
//       "Engkanto Live it Up Lager",
//       "Engkanto High Hive Honey Ale",
//       "Engkanto Paint Me Purple - Ube Lager",
//       "Engkanto Mango Nation Hazy IPA",
//       "Engkanto Green Lava Double IPA",
//     ],
//   };

//   @override
//   void initState() {
//     super.initState();
//     _inputId = TextEditingController(text: widget.item.inputId);
//     _merchandiserNameController =
//         TextEditingController(text: widget.item.merchandiserName);
//     _outletController = TextEditingController(text: widget.item.outlet);
//     _categoryController = TextEditingController();
//     _itemController = TextEditingController();
//     _quantityController = TextEditingController();
//     _driverNameController = TextEditingController();
//     _plateNumberController = TextEditingController();
//     _pullOutReasonController = TextEditingController();

//     _quantityController.addListener(_checkIfAllFieldsAreFilled);
//     _driverNameController.addListener(_checkIfAllFieldsAreFilled);
//     _plateNumberController.addListener(_checkIfAllFieldsAreFilled);
//     _pullOutReasonController.addListener(_checkIfAllFieldsAreFilled);

//     // if (_categoryToSkuDescriptions.isNotEmpty) {
//     //   selectedCategory = widget.item.category.isEmpty
//     //       ? _categoryToSkuDescriptions.keys.first
//     //       : widget.item.category;
//     //   updateItemOptions(selectedCategory);
//     // }

//     if (_categoryToSkuDescriptions.isNotEmpty) {
//       // Assuming you have a way to get the current category, e.g. 'Variant'
//       String category =
//           'Variant'; // Replace this with the actual category you want to use
//       updateItemOptions(category); // Pass the category
//     }
//   }

//   @override
//   void dispose() {
//     _merchandiserNameController.dispose();
//     _outletController.dispose();
//     _inputId.dispose();
//     _categoryController.dispose();
//     _itemController.dispose();
//     _quantityController.dispose();
//     _driverNameController.dispose();
//     _plateNumberController.dispose();
//     _pullOutReasonController.dispose();
//     super.dispose();
//   }

//   void updateItemOptions(String category) {
//     setState(() {
//       itemOptions =
//           _categoryToSkuDescriptions[category] ?? []; // Use the passed category
//       selectedItem = itemOptions.isNotEmpty ? itemOptions.first : '';
//       _itemController.text =
//           selectedItem; // Make sure _itemController is defined in your widget
//     });
//   }

//   void _toggleDropdown(String category) {
//     setState(() {
//       selectedCategory = category;
//       updateItemOptions(category);
//     });
//   }

//   void _checkIfAllFieldsAreFilled() {
//     setState(() {
//       isSaveButtonEnabled = _quantityController.text.isNotEmpty &&
//           _driverNameController.text.isNotEmpty &&
//           _plateNumberController.text.isNotEmpty &&
//           _pullOutReasonController.text.isNotEmpty;
//     });
//   }

//   Future<void> _confirmSaveReturnToVendor() async {
//     if (!isSaveButtonEnabled) return;
//     bool confirmed = await showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Save Confirmation'),
//           content: Text('Do you want to save this Return to Vendor?'),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(false); // Return false if cancelled
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(true); // Return true if confirmed
//               },
//               child: Text('Confirm'),
//             ),
//           ],
//         );
//       },
//     );

//     if (confirmed) {
//       _saveChanges();
//     }
//   }

//   void _saveChanges() {
//     if (_formKey.currentState!.validate()) {
//       // Create an updated item object with the new values
//       final updatedItem = ReturnToVendor(
//         id: widget.item.id, // keep the same id to update the correct document
//         inputId: _inputId.text,
//         userEmail: widget.item.userEmail,
//         date: widget.item.date,
//         merchandiserName: _merchandiserNameController.text,
//         outlet: _outletController.text,
//         //category: selectedCategory,
//         item: _itemController.text,
//         quantity: _quantityController.text,
//         driverName: _driverNameController.text,
//         plateNumber: _plateNumberController.text,
//         pullOutReason: _pullOutReasonController.text,
//       );

//       // Call the method to update the item in the database
//       MongoDatabase.updateItemInDatabase(updatedItem);

//       // Navigate back to the RTV list screen
//       Navigator.pop(context);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//         onWillPop: () async => false,
//         child: Scaffold(
//           appBar: AppBar(
//             leading: IconButton(
//               icon: Icon(
//                 Icons.arrow_back,
//                 color: Colors.white,
//               ), // Use arrow_back icon
//               onPressed: () {
//                 Navigator.pop(context); // Return to the previous screen
//               },
//             ),
//             title: Text(
//               'UPDATE RTV',
//               style:
//                   TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//             ),
//             backgroundColor: Color.fromARGB(255, 26, 20, 71),
//             elevation: 0,
//           ),
//           body: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Form(
//               key: _formKey,
//               child: ListView(
//                 children: [
//                   Text(
//                     'RTV NUMBER',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   TextFormField(
//                     controller: _inputId,
//                     readOnly: true,
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'MERCHANDISER',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   TextFormField(
//                     controller: _merchandiserNameController,
//                     readOnly: true,
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'OUTLET',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   TextFormField(
//                     controller: _outletController,
//                     readOnly: true,
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children:
//                         _categoryToSkuDescriptions.keys.map((String category) {
//                       return OutlinedButton(
//                         onPressed: null, // Disable button interaction
//                         style: OutlinedButton.styleFrom(
//                           side: BorderSide(
//                             width: 2.0,
//                             color: selectedCategory == category
//                                 ? Color.fromARGB(255, 26, 20, 71)
//                                 : Color.fromARGB(255, 26, 20, 71),
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                         ),
//                         child: Text(
//                           category,
//                           style: TextStyle(color: Colors.black),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'SKUs',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   SizedBox(height: 10),
//                   DropdownButtonFormField<String>(
//                     value: selectedItem,
//                     items: itemOptions.map((String item) {
//                       return DropdownMenuItem<String>(
//                         value: item,
//                         child: SizedBox(
//                           width: 250,
//                           child: Tooltip(
//                             message: item,
//                             child: Text(
//                               item,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                     onChanged: null, // Disable the dropdown interaction
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(
//                         borderSide: BorderSide(),
//                       ),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'QUANTITY',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   TextFormField(
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                     ),
//                     controller: _quantityController,
//                     keyboardType: TextInputType.number,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter quantity';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'DRIVER NAME',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   TextFormField(
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                     ),
//                     controller: _driverNameController,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter driver name';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'PLATE NUMBER',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   TextFormField(
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                     ),
//                     controller: _plateNumberController,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter plate number';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'REMARKS',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   TextFormField(
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                     ),
//                     controller: _pullOutReasonController,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter pull out reason';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 50),
//                   Align(
//                     alignment: Alignment.bottomCenter,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: isSaveButtonEnabled
//                             ? Color.fromARGB(255, 26, 20, 71)
//                             : Colors.grey.shade600, // Changed to .shade600
//                         padding: EdgeInsets.all(20),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(100),
//                         ),
//                         disabledBackgroundColor:
//                             Colors.grey.shade600, // Added this line
//                       ),
//                       onPressed: isSaveButtonEnabled
//                           ? _confirmSaveReturnToVendor
//                           : null,
//                       child: Text(
//                         "Save Changes",
//                         style: GoogleFonts.roboto(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ));
//   }

//   void _showItemPicker() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return ListView.builder(
//           itemCount: itemOptions.length,
//           itemBuilder: (context, index) {
//             final item = itemOptions[index];
//             return ListTile(
//               title: Text(item),
//               onTap: () {
//                 setState(() {
//                   selectedItem = item;
//                   _itemController.text = selectedItem;
//                 });
//                 Navigator.pop(context);
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }

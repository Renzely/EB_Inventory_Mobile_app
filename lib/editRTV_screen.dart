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
//     'V1': [
//       "KOPIKO COFFEE CANDY 24X175G",
//       "KOPIKO COFFEE CANDY JAR 6X560G",
//       "KOPIKO CAPPUCCINO CANDY 24X175G",
//       "FRES BARLEY MINT 24X50X3G",
//       "FRES MINT BARLEY JAR 12X200X3G",
//       "FRES CHERRY CANDY, 24 X 50 X 3G",
//       "FRES CHERRY JAR, 12X 200 X 3G",
//       "FRES GRAPE CANDY, 24 X 50 X 3G",
//       "FRES GRAPE JAR, 12 X 200 X 3G",
//       "FRES APPLE PEACH 24 X 50 X 3G",
//       "BENG BENG CHOCOLATE 12 X 10 X 26.5G",
//       "BENG BENG SHARE IT 16 X 95G",
//       "CAL CHEESE 10X20X8.5G",
//       "CAL CHEESE 60X35G",
//       "CAL CHEESE 60X53.5G",
//       "CAL CHEESE CHEESE CHOCO 60X53.5G",
//       "CAL CHEESE CHEESE CHOCO 60X35G",
//       "MALKIST CHOCOLATE 30X10X18G",
//       "WAFELLO CHOCOLATE WAFER 60X53.5G",
//       "WAFELLO CHOCOLATE WAFER 60X35G",
//       "WAFELLO BUTTER CARAMEL 60X35G",
//       "WAFELLO COCO CREME 60X35G",
//       "WAFELLO CREAMY VANILLA 20X10X20.5G PH",
//       "VALMER CHOCOLATE 12X10X54G",
//       "SUPERSTAR TRIPLE CHOCOLATE 12 X10 X 18G",
//       "DANISA BUTTER COOKIES 12X454G",
//       "WAFELLO BUTTER CARAMEL 60X53.5G",
//       "WAFELLO COCO CREME 60X53.5G",
//       "WAFELLO CHOCOLATE 48G X 60",
//       "WAFELLO CHOCOLATE 21G X 10 X 20",
//       "WAFELLO BUTTER CARAMEL 48G X 60",
//       "WAFELLO BUTTER CARAMEL 20.5G X 10 X 20",
//       "WAFELLO COCO CRÈME 48G X 60",
//       "WAFELLO COCONUT CRÈME 20.5G X 10 X 20",
//       "CAL CHEESE 60 X 48G",
//       "CAL CHEESE 20 X 10 X 20G",
//       "CAL CHEESE 20 X 20 X 8.5G",
//       "CAL CHEESE CHOCO 60 X 48G",
//       "CAL CHEESE CHOCO 20 X 10 X 20.5G",
//       "VALMER SANDWICH CHOCOLATE 12X10X36G",
//       "MALKIST CAPPUCCINO 30X10X18G PH",
//       "FRES CHERRY JAR PROMO",
//       "FRES BARLEY JAR PROMO",
//       "FRES GRAPE JAR PROMO",
//       "FRES MIX CANDY JAR PROMO",
//       "CAL CHEESE 20G (9+1 PROMO)",
//       "WAFELLO CHOCOLATE 21G (9+1 PROMO)",
//       "WAFELLO COCO CREME 20.5G (9+1 PROMO)",
//       "WAFELLO BUTTER CARAMEL 20.5G (9+1 PROMO)",
//       "FRES MIXED CANDY JAR 12 X 600G",
//       "WAFELLO CREAMY VANILLA 60X48G PH",
//       "MALKIST SWEET GLAZED 12X10X28G PH",
//       "MALKIST BARBECUE 12X10X28G PH"
//     ],
//     'V2': [
//       "Kopiko Black 3 in One Hanger 24 x 10 x 30g",
//       "KOPIKO BLACK 3-IN-1 BAG 8 X 30 X 30G",
//       "Kopiko Black 3 in One Promo Twin 12 x 10 x 2 x 30g",
//       "Kopiko Brown Coffee hg 27.5g 24x10x27.5g",
//       "Kopiko Brown Coffee Pouch 24x10x27.5g",
//       "Kopiko Brown Coffee Bag 8x30x27.5g",
//       "Kopiko Brown Promo Twin 12 x 10 x 53g",
//       "Kopiko Cappuccino Hanger 24 x 10 x 25g",
//       "Kopiko Cappuccino Pouch 24x10x25g",
//       "Kopiko Cappuccino Bag 8x30x25g",
//       "Kopiko L.A. Coffee hanger 24x10x25g",
//       "Kopiko LA Coffee Pouch 24x10x25g",
//       "Kopiko Blanca hanger 24x10x30g",
//       "KOPIKO BLANCA, POUCH 24 X 10 X 30G",
//       "KOPIKO BLANCA, BAG 8 X 30 X 30G",
//       "Kopiko Blanca Twinpack 12 X 10 X 2 X 29G",
//       "Toracafe White and Creamy 12 X (10 X 2) X 26G",
//       "Kopiko Creamy Caramelo 12 x (10 x 2) x 25g",
//       "Kopiko Double Cups 24 x 10 x 36g",
//       "ENERGEN CHOCOLATE HANGER 24 X 10 X 40G",
//       "Energen Chocolate Pouch 24x10x40g",
//       "Energen Chocolate Bag 8x30x40g",
//       "ENERGEN VANILLA HANGER 24 X 10 X 40G",
//       "Energen Vanilla Pouch 24x10x40g",
//       "Energen Vanilla Bag 8x30x40g",
//       "Energen Champion NBA Hanger 24 x 10 x 35g",
//       "Energen Pandesal Mate 24 x 10 x 30g",
//       "ENERGEN CHAMPION 12X10X2X35G PH",
//       "Kopiko Cafe Mocha TP 12X10X(2X25.5G) PH",
//       "Energen Champion NBA TP 15 x 8 x 2 x30g ph",
//       "KOPIKO BLACK 3IN1 TWINPACK 12X10X2X28G",
//       "KOPIKO BLACK 3IN1 HANGER 24X10X30G UNLI",
//       "KOPIKO BLACK 3IN1 TP 12X10X2X28G UNLI",
//       "KOPIKO BROWN HANGER 24X10X27.5G UNLI",
//       "KOPIKO BROWN TP 12X10X2X26.5G UNLI",
//       "CHAMPION HANGER 17+3",
//       "Champion Twin Pack 13+3",
//       "Kopiko Blanca TP Banded 6 x (18 + 2) x 2 x 29g",
//       "KOPIKO BROWN COFFEE TWINPACK BUY 12 SAVE 13 PROMO",
//       "KOPIKO BLACK TWIN BUY 10 SAVE 13",
//       "KOPIKO BLANCA HANGER GSK 12 X 2 X 10 X 30G",
//       "BLANCA TP 10+1",
//       "Champion Hanger 20x(10+2) x 35g/30g",
//       "ENERGEN CHAMPION 40X345G",
//       "KOPIKO BLACK 3-IN-1 POUCH 24 X 10 X 30G"
//     ],
//     'V3': [
//       "Le Minerale 24x330ml",
//       "Le Minerale 24x600ml",
//       "Le Minerale 12x1500ml",
//       "LE MINERALE 4 X 5000ML",
//       "KOPIKO LUCKY DAY 24BTL X 180ML",
//       "KLD 5+1 Bundling"
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

//     if (_categoryToSkuDescriptions.isNotEmpty) {
//       selectedCategory = widget.item.category.isEmpty
//           ? _categoryToSkuDescriptions.keys.first
//           : widget.item.category;
//       updateItemOptions(selectedCategory);
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
//       itemOptions = _categoryToSkuDescriptions[category] ?? [];
//       selectedItem = itemOptions.isNotEmpty ? itemOptions.first : '';
//       _itemController.text = selectedItem;
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
//         category: selectedCategory,
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
//               icon: Icon(Icons.arrow_back), // Use arrow_back icon
//               onPressed: () {
//                 Navigator.pop(context); // Return to the previous screen
//               },
//             ),
//             title: Text(
//               'Edit RTV',
//               style:
//                   TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//             ),
//             backgroundColor: Colors.green[600],
//             elevation: 0,
//           ),
//           body: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Form(
//               key: _formKey,
//               child: ListView(
//                 children: [
//                   Text(
//                     'Input ID',
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
//                     'Merchandiser',
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
//                     'Outlet',
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
//                   Text(
//                     'Category',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   SizedBox(height: 10),
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
//                                 ? Colors.green
//                                 : Colors.blueGrey.shade200,
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
//                     'SKU Description',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   SizedBox(height: 10),
//                   DropdownButtonFormField<String>(
//                     value: selectedItem,
//                     items: itemOptions.map((String item) {
//                       return DropdownMenuItem<String>(
//                         value: item,
//                         child: SizedBox(
//                           width: 350,
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
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                       enabled:
//                           false, // Optionally adjust the decoration to indicate read-only state
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'Quantity',
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
//                     'Driver Name',
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
//                     'Plate Number',
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
//                     'Pull Out Reason',
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
//                         backgroundColor:
//                             isSaveButtonEnabled ? Colors.green : Colors.grey,
//                         padding: EdgeInsets.all(
//                             20), // Increase padding to make the button larger
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(
//                               100), // Increased from 50 to 100 for a larger curve
//                         ),
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

import 'dart:async';
import 'dart:io';

import 'package:date_time_picker/date_time_picker.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:milk_duvet/pages/domainAPI.dart';
import 'package:intl/intl.dart';


import '../models/coolers.dart';
import '../models/pickups.dart';
import '../widgets/drawer.dart';
import 'dbHelper.dart';

class DriverPickups extends StatefulWidget {
  const DriverPickups({Key? key}) : super(key: key);

  @override
  State<DriverPickups> createState() => _DriverPickupsState();
}

class _DriverPickupsState extends State<DriverPickups> {
  TextEditingController quantityController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final formKey = GlobalKey<FormState>();
  final formater = NumberFormat("#,###", "en_US");


  List<Cooler> coolers = [];
  List<Pickups> pickups = [];
  List<Pickups> filterpickups = [];

  List<InitiatedPickups> iniatedpickups = [];
  List<InitiatedPickups> filteriniatedpickups = [];
  var coolerID;
  var loading = false;
  var isLoading = true;
  var updateLoading = false;
  String? userId;
  String? token;
  Future<void> getUserInfo() async {
    var db = await DBHelper.instance.database;
    await db.rawQuery("select * from users").then((value) {
      for (var element in value) {
        setState(() {
          userId = element['userId'].toString();
          token = element['token'].toString();
        });
      }
      fetchCoolers();
      fetchPickups();
      initiatedPickups();
    });
  }

  Future<void> fetchCoolers() async{
    Dio dio =Dio();
    var response = await dio.get("$myDomain/coolers",
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'application/json',
        ));

    if(response.statusCode==200){
      var responses = response.data;
      setState(() {
        coolers.clear();
        responses.forEach((element) {
          coolers.add(Cooler(
            coolerId: element['id'].toString(),
            coolerName: element['name'].toString(),
            coolerQuantity: element['quantity'].toString()
          ));
        });

      });
    }else{
      throw Exception("Failed to fetch");
    }
  }

  Future<void> fetchPickups() async{
    Dio dio =Dio();
    var response = await dio.get("$myDomain/deliveries",
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'application/json',
        ));

    if(response.statusCode==200){
      var responses = response.data;
      setState(() {
        filterpickups=pickups;
        pickups.clear();
        responses.forEach((element) {
          pickups.add(Pickups(
            coolerId: element['cooler_id'].toString(),
            driverId: element['driver_id'].toString(),
            quantityPicked: element['quantity_picked'].toString(),
            datePicked: element['date_picked'].toString(),
            coolerName: element['cooler'].toString()

          ));
        });
        isLoading = false;

      });
    }else{
      throw Exception("Failed to fetch");
    }
  }

  Future<void> initiatedPickups() async{
    Dio dio =Dio();
    var response = await dio.get("$myDomain/initiated_pickups",
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'application/json',
        ));

    if(response.statusCode==200){
      var responses = response.data;
      setState(() {
        filteriniatedpickups=iniatedpickups;
        iniatedpickups.clear();
        responses.forEach((element) {
          iniatedpickups.add(InitiatedPickups(
            id: element['id'].toString(),
              coolerId: element['cooler_id'].toString(),
              driverId: element['driver_id'].toString(),
              quantityPicked: element['quantity_picked'].toString(),
              datePicked: element['date_picked'].toString(),
              coolerName: element['cooler'].toString(),
              totalQuantity: element['totalQuantity'].toString()

          ));
        });
        isLoading = false;

      });
    }else{
      throw Exception("Failed to fetch");
    }
  }

  updatePickup( var items) async {

    var  options= BaseOptions(
      headers: {"Accept" : "application/json",'Authorization': 'Bearer $token'},
    );
    final Dio dio = Dio(options);
    try{
      final response = await dio.post(
        '$myDomain/appupdate',
        data: items,
      );
      if(response.statusCode==200){
        showUpdateSuccess();
        setState(() {
          updateLoading=false;
        });


      }else{
        Fluttertoast.showToast(msg: "Failed to Add");
        setState(() {
          updateLoading=false;
        });

      }
    } on DioError catch(e){
      setState(() {
        updateLoading=false;

      });

    }
  }

  deletePickup(var items) async {
    var  options= BaseOptions(
      headers: {"Accept" : "application/json",'Authorization': 'Bearer $token'},
    );
    final Dio dio = Dio(options);
    try{
      final response = await dio.post(
        '$myDomain/appdelete',
        data: items,
      );
      if(response.statusCode==200){
        showDeleteSuccess();
        setState(() {
          updateLoading=false;
        });


      }else{
        Fluttertoast.showToast(msg: "Failed to Add");
        setState(() {
          updateLoading=false;
        });

      }
    } on DioError catch(e){
      setState(() {
        updateLoading=false;

      });

    }
  }

  addPickup() async {

    var stockItems = {
      'cooler_id':coolerID,
      'quantity_picked':quantityController.text.trim(),
      'date_picked':dateController.text.trim(),
    };

    var  options= BaseOptions(
      headers: {"Accept" : "application/json",'Authorization': 'Bearer $token'},
    );
    final Dio dio = Dio(options);
    try{
      final response = await dio.post(
        '$myDomain/deliveries',
        data: stockItems,
      );
      if(response.statusCode==200){
        showSuccess();
        quantityController.text = '';
        setState(() {
          loading=false;
        });


      }else{
        Fluttertoast.showToast(msg: "Failed to Add");
        setState(() {
          loading=false;
        });

      }
    } on DioError catch(e){
      setState(() {
        loading=false;
      });

    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserInfo();
    dateController.text = DateFormat("yyyy-MM-dd").format(DateTime.now());


  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showExitDialogue();
        return true; // Return true to allow the back button press to be handled
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(
                  text: "Approved Pickups",
                ),
                // Tab(text: "Profile"),
                Tab(text: "Initiated Pickups"),
              ],
            ),
            title: const Text('MY PICKUPS'),
            centerTitle: true,
            elevation: 0,
          ),
          drawer: const SideBar(),
          body: TabBarView(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 5,vertical: 10),
                child: Column(
                  children:  [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "search by name and date",
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15.0),
                        border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10)),
                        suffixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filterpickups = pickups
                              .where((items) => (items.coolerName
                              .toString()
                              .toLowerCase()
                              .contains(value.toLowerCase())) | (items.datePicked
                              .toString()
                              .toLowerCase()
                              .contains(value.toLowerCase())))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 20,),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        Expanded(
                            flex: 3,
                            child: Text('Station(MCC)',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                        Expanded(
                            flex: 3,
                            child: Text("Quantity(Ltr)",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                        Expanded(
                            flex: 2,
                            child: Text("Date",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),))
                      ],
                    ),
                    const SizedBox(height: 10,),
                    isLoading==false?Expanded(
                      child: filterpickups.isNotEmpty?ListView.builder(
                          shrinkWrap: true,
                          itemCount: filterpickups.length,
                          itemBuilder: (context, index){
                            var items = filterpickups[index];
                            return Container(
                              color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              height: 50,
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 3,
                                      child: Text(items.coolerName.toString())),
                                  Expanded(
                                      flex: 2,
                                      child: Text(formater.format(int.parse(items.quantityPicked.toString())))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(items.datePicked.toString()))
                                ],

                              ),
                            );

                          }
                      ):const Center(child: Text("NO DATA FOUND", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),),),
                    ):Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:const [
                        Center(child: CircularProgressIndicator(),),
                        SizedBox(width: 10,),
                        Text("Fetching your pickups")
                      ],
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 5,vertical: 10),
                child: Column(
                  children:  [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "search by mcc name",
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15.0),
                        border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10)),
                        suffixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filteriniatedpickups = iniatedpickups
                              .where((items) => (items.coolerName
                              .toString()
                              .toLowerCase()
                              .contains(value.toLowerCase())))
                              .toList();

                        });
                      },
                    ),
                    const SizedBox(height: 20,),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        Expanded(
                            flex: 3,
                            child: Text('Station(MCC)',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                        Expanded(
                            flex: 2,
                            child: Text("Quantity(L)",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                        Expanded(
                            flex: 2,
                            child: Text("Action",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),))
                      ],
                    ),
                    const SizedBox(height: 10,),
                    isLoading==false?Expanded(
                      child: filteriniatedpickups.isNotEmpty?ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteriniatedpickups.length,
                          itemBuilder: (context, index){
                            var items = filteriniatedpickups[index];
                            return Container(
                              color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              height: 50,
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 3,
                                      child: Text(items.coolerName.toString())),
                                  Expanded(
                                      flex: 2,
                                      child: Text(formater.format(int.parse(items.quantityPicked.toString())))),
                                  Expanded(
                                      flex: 2,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                coolerID=items.coolerId;
                                                var item = {
                                                  'id':items.id,
                                                  'quantityPicked': items.quantityPicked,
                                                  'cooler_id': items.coolerId,
                                                  'datePicked': items.datePicked,
                                                  'coolerName' : items.coolerName,
                                                  'totalQuantity':items.totalQuantity

                                                };

                                                editMilkPickup(item);
                                              });

                                            },
                                              child: const Icon(Icons.edit, color: Colors.blue,size: 25,)),
                                          GestureDetector(onTap: (){
                                            var item = {
                                              'id':items.id
                                            };
                                            showDeleteAlert(item);
                                          },child: const Icon(Icons.delete, color: Colors.red,size: 25,)),
                                        ],
                                      )
                                  )
                                ],

                              ),
                            );

                          }
                      ):const Center(child: Text("NO DATA FOUND", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),),),
                    ):Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:const [
                        Center(child: CircularProgressIndicator(),),
                        SizedBox(width: 10,),
                        Text("Fetching your pickups")
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton.extended(
              onPressed: (){
                addMilkPickup();
                fetchPickups();
                initiatedPickups();
              },

              label: Row(
                children: const [
                  Icon(Icons.add),
                  SizedBox(width: 5,),
                  Text("Add New"),
                ],
              )
          ),
        ),
      ),
    );
  }
  Future<void> showExitDialogue() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            height: 100,
            color: Colors.red,
            child: const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 60.0,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text('Are you sure you want to exit the application',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Exit', style: TextStyle(color:Colors.red),),
                  onPressed: () {
                    exit(0);
                  },
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Future<void> addMilkPickup() async {
    var originalCoolerQty ="0";
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState){
          return Dialog(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text("FILL IN THE MILK QTY FOR PICKUP", style: TextStyle(fontWeight: FontWeight.bold),),
                      const Divider(height: 10, thickness: 1,),
                      const SizedBox(height: 10,),
                      DropdownSearch<Cooler>(
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                        ),
                        items: coolers,
                        itemAsString: (Cooler item) =>
                            item.coolerName.toString(),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15.0),
                              labelText: "Select Cooler",
                              enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5))),
                        ),
                        onChanged: ((value) {
                          setState((){
                            coolerID = value?.coolerId;
                            originalCoolerQty = value!.coolerQuantity.toString();
                          });
                          // quantityController.text= value!.coolerQuantity.toString();
                        }),
                        validator: (value) {
                          if (value == null || value.coolerId == '') {
                            return "Please choose a Cooler ";
                          }
                          return null;
                        },
                        // selectedItem: selectedPackage,
                      ),
                      const SizedBox(height: 20,),
                      TextFormField(
                        inputFormatters: [ FilteringTextInputFormatter.allow(RegExp("[0-9]")), ],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 15.0),
                          labelText: 'Milk Quantity',
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        controller: quantityController,
                        validator:  (value) {
                          if (value == null || value.isEmpty) {
                            return "This field is required";
                          }else if(value=='0'){
                            return "Quantity cannot be 0";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20,),

                      DateTimePicker(
                        controller: dateController,
                        type: DateTimePickerType.date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        dateLabelText: 'Date',
                        decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 10),
                            border: OutlineInputBorder(
                                borderSide:
                                const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10)),
                            labelText: "Select date",
                            suffixIcon: const Icon(
                              Icons.calendar_month,
                              color: Colors.blue,
                            )),
                      ),
                      const SizedBox(height: 20,),
                      Row(

                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              height: 35,
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey,
                              ),
                              child: const Center(
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  )),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_formKey.currentState!.validate()) {

                                if(int.parse(quantityController.text.toString().replaceAll(",", ""))>int.parse(originalCoolerQty.toString())){
                                  showLessQtyAlert(originalCoolerQty.toString());
                                  setState(() {
                                    loading=false;
                                  });
                                } else{
                                  addPickup();
                                  setState(() {
                                    loading=true;
                                  });
                                }
                              }
                            },
                            child: loading==false?Container(
                              height: 35.0,
                              width: 100.0,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: Colors.blue),
                              child: const Center(
                                  child: Text(
                                    "save",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  )),
                            ):const Center(child: CircularProgressIndicator(),)
                          ),
                        ],

                      )
                    ],

                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> showSuccess() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Icon(
            Icons.check_circle_outline,
            color: Colors.blue,
            size: 60.0,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text('Request has been sent to the Manager for approval',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          actions: <Widget>[
            Center(
              child: TextButton(
                child: const Text(
                  'OK',
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w900),
                ),
                onPressed: () {
                  fetchPickups();
                  initiatedPickups();
                  Navigator.pop(context);
                  Navigator.pop(context);

                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> showUpdateSuccess() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Icon(
            Icons.check_circle_outline,
            color: Colors.blue,
            size: 60.0,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text('Pickup request has been updated successfully',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          actions: <Widget>[
            Center(
              child: TextButton(
                child: const Text(
                  'OK',
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w900),
                ),
                onPressed: () {
                  fetchPickups();
                  initiatedPickups();
                  Navigator.pop(context);
                  Navigator.pop(context);

                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> showLessQtyAlert(String originalCoolerQty) async {

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Icon(
            Icons.info,
            color: Colors.orange[800],
            size: 60.0,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text("The milk quantity ${quantityController.text.toString()} requested is greater than the available milk stock ${originalCoolerQty.toString()}",
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          actions: <Widget>[
            Center(
              child: TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 18.0,
                      fontWeight: FontWeight.w900),
                ),
                onPressed: () {
                  Navigator.pop(context);

                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> showDeleteAlert(var item) async {
    String id=item['id'];
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Icon(
            Icons.cancel,
            color: Colors.red,
            size: 60.0,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text('This action will delete this request',
                    textAlign: TextAlign.center),
                Text('Are sure you want to continue?', textAlign: TextAlign.center),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w900),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text(
                    'Yes',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w900),
                  ),
                  onPressed: () {
                    var items = {
                      'id':id
                    };
                    deletePickup(items);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> showDeleteSuccess() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Icon(
            Icons.check_circle_outline,
            color: Colors.blue,
            size: 60.0,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text('Request deleted successfully',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          actions: <Widget>[
            Center(
              child: TextButton(
                child: const Text(
                  'OK',
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w900),
                ),
                onPressed: () {
                  initiatedPickups();
                  fetchPickups();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> editMilkPickup(var item) async {
    String id = item['id'];
    var originalCoolerQty =item['totalQuantity'];
    var selectedCooler = Cooler(coolerName: item['coolerName'], coolerId: item['coolerId']);
    dateController.text = item['datePicked'];
    quantityController.text  = item['quantityPicked'];
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState){
          return Dialog(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      const Text("EDIT MILK QTY FOR PICKUP", style: TextStyle(fontWeight: FontWeight.bold),),
                      const Divider(height: 10, thickness: 1,),
                      const SizedBox(height: 10,),
                      DropdownSearch<Cooler>(
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                        ),
                        items: coolers,
                        itemAsString: (Cooler item) =>
                            item.coolerName.toString(),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15.0),
                              labelText: "Select Cooler",
                              enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5))),
                        ),
                        selectedItem: selectedCooler,
                        onChanged: ((value) {
                          setState((){
                            coolerID = value?.coolerId;
                            originalCoolerQty = value!.coolerQuantity.toString();
                          });
                        }),
                        validator: (value) {
                          if (value == null || value.coolerId == '') {
                            return "Please choose a Cooler ";
                          }
                          return null;
                        },

                      ),
                      const SizedBox(height: 20,),
                      TextFormField(
                        inputFormatters: [ FilteringTextInputFormatter.allow(RegExp("[0-9]")), ],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 15.0),
                          labelText: 'Milk Quantity',
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        controller: quantityController,
                        validator:  (value) {
                          if (value == null || value.isEmpty) {
                            return "This field is required";
                          }else if(value=='0'){
                            return "Quantity cannot be 0";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20,),

                      DateTimePicker(
                        controller: dateController,
                        type: DateTimePickerType.date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        dateLabelText: 'Date',
                        decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 10),
                            border: OutlineInputBorder(
                                borderSide:
                                const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10)),
                            labelText: "Select date",
                            suffixIcon: const Icon(
                              Icons.calendar_month,
                              color: Colors.blue,
                            )),
                      ),
                      const SizedBox(height: 20,),
                      Row(

                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              height: 35,
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey,
                              ),
                              child: const Center(
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  )),
                            ),
                          ),
                          GestureDetector(
                              onTap: () {
                                if (formKey.currentState!.validate()) {
                                  if(int.parse(quantityController.text.toString().replaceAll(",", ""))>int.parse(originalCoolerQty.toString())){
                                    showLessQtyAlert(originalCoolerQty.toString());
                                    setState(() {
                                      updateLoading=false;
                                    });
                                  } else{
                                    var editedItems = {
                                    'id': id,
                                    'cooler_id':coolerID,
                                    'quantity_picked':quantityController.text.trim(),
                                    'date_picked':dateController.text.trim(),
                                };
                                    updatePickup(editedItems);
                                    setState(() {
                                      updateLoading=true;
                                    });

                                  }
                                }
                              },
                              child: updateLoading==false?Container(
                                height: 35.0,
                                width: 100.0,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: Colors.blue),
                                child: const Center(
                                    child: Text(
                                      "save",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                    )),
                              ):const Center(child: CircularProgressIndicator(),)
                          ),
                        ],

                      )
                    ],

                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }


}

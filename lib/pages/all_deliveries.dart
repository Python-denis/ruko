import 'dart:async';

import 'package:date_time_picker/date_time_picker.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:milk_duvet/models/riders.dart';
import 'package:intl/intl.dart';


import '../models/deliveries.dart';
import '../widgets/drawer.dart';
import 'dbHelper.dart';
import 'domainAPI.dart';

class AllDeliveries extends StatefulWidget {
  const AllDeliveries({Key? key}) : super(key: key);

  @override
  State<AllDeliveries> createState() => _AllDeliveriesState();
}

class _AllDeliveriesState extends State<AllDeliveries> {
  var isLoading = true;
  var loading = false;
  var date;
  var rideID;
  TextEditingController quantityController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final formater = NumberFormat("#,###", "en_US");


  String? token;
  String? coolerId;
  String? userId;
  var alldeliveries = [];
  var filteralldeliveries = [];
  List<Rider> riders = [];


  Future<void> getUserInfo() async {
    var db = await DBHelper.instance.database;
    await db.rawQuery("select * from users").then((value) {
      for (var element in value) {
        setState(() {
          coolerId = element['coolerId'].toString();
          userId = element['userId'].toString();
          token = element['token'].toString();
        });
      }
      fetchDeliveries();
      fetchRiders();
    });
  }

  Future<void> fetchDeliveries() async{
    Dio dio =Dio();
    var response = await dio.get("$myDomain/pickups",
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'application/json',
        ));

    if(response.statusCode==200){
      var responses = response.data['pickups'];
      print('responses');
      print(responses);
      setState(() {
        filteralldeliveries=alldeliveries;
        alldeliveries.clear();
        responses.forEach((element) {
          alldeliveries.add(Deliveries(
            id: element['id'].toString(),
            coolerId: element['cooler']['name'].toString(),
            rideName: element['user']['full_name'].toString(),
            quantity: element['quantity'].toString(),
            dateReceived: element['date_received'].toString(),
          ));
        });
        setState(() {
          isLoading = false;
        });
      });
    }else{
      throw Exception("Failed to fetch");
    }
  }

  Future<void> fetchRiders() async{
    Dio dio =Dio();
    var response = await dio.get("$myDomain/riders",
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'application/json',
        ));

    if(response.statusCode==200){
      var responses = response.data;
      setState(() {
        riders.clear();
        responses.forEach((element) {
          riders.add(Rider(
            riderId: element['id'].toString(),
            rideName: element['full_name'].toString(),
          ));
        });

      });
    }else{
      throw Exception("Failed to fetch");
    }
  }

  addStock() async {

    var stockItems = {
      'user_id':rideID,
      'quantity':quantityController.text.trim(),
      'date_received':dateController.text.trim(),
    };

    var  options= BaseOptions(
      headers: {"Accept" : "application/json",'Authorization': 'Bearer $token'},
    );
    final Dio dio = Dio(options);
    try{
      final response = await dio.post(
        '$myDomain/pickups',
        data: stockItems,
      );
      if(response.statusCode==200){
        showSuccess();
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
    return  Scaffold(
      appBar: AppBar(
        title: const Text("ALL DELIVERIES"),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: const SideBar(),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: Column(
          children: [
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
                  filteralldeliveries = alldeliveries
                      .where((items) => (items.rideName
                      .toString()
                      .toLowerCase()
                      .contains(value.toLowerCase())) | (items.dateReceived
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
                    child: Text('Farmer',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                Expanded(
                  flex: 2,
                    child: Text("Qty(L)",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                Expanded(
                  flex: 2,
                    child: Text("Date",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),))
              ],
            ),
            const SizedBox(height: 10,),
            isLoading==false?
            Expanded(
                child: filteralldeliveries.isNotEmpty? ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteralldeliveries.length,
                    itemBuilder: (context, index){
                      var items = filteralldeliveries[index];
                      return Container(
                        color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        height: 50,
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text(items.rideName)),
                            Expanded(
                                flex: 2,
                                child: Text(formater.format(int.parse(items.quantity)))),
                            Expanded(
                                flex: 2,
                                child: Text(items.dateReceived))
                          ],

                        ),
                      );

                    }
                )
                    :const Center(child: Text("NO DELIVERIES FOUND", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),),)
            ):Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:const [
                  Center(child: CircularProgressIndicator(),),
                  SizedBox(width: 10,),
                  Text("Fetching Deliveries"),
                ],
              )


          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (){
          addMilkStock();
        },
        label: Row(
          children: const [
            Icon(Icons.add),
            SizedBox(width: 5,),
            Text("Add New")
          ],
        ),
      ),
    );
  }

  Future<void> addMilkStock() async {
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
                      const Text("ADD MILK STOCK", style: TextStyle(fontWeight: FontWeight.bold),),
                      const Divider(height: 10, thickness: 1,),
                      const SizedBox(height: 10,),
                      DropdownSearch<Rider>(
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                        ),
                        items: riders,
                        itemAsString: (Rider item) =>
                            item.rideName.toString(),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15.0),
                              labelText: "Select Farmer",
                              enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5))),
                        ),
                        onChanged: ((value) {
                          rideID = value?.riderId;
                        }),
                        validator: (value) {
                          if (value == null || value.riderId == '') {
                            return "Please choose a farmer";
                          }
                          return null;
                        },
                        // selectedItem: selectedPackage,
                      ),
                      const SizedBox(height: 20,),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [ FilteringTextInputFormatter.allow(RegExp("[0-9]")), ],

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
                        // controller: dateController,
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
                        controller: dateController,
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
                                  addStock();
                                  setState(() {
                                    loading=true;
                                  });
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
                                      "Add Stock",
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
                Text('Stock Added Successfully',
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
                  fetchDeliveries();
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
}


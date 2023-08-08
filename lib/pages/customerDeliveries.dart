import 'dart:async';

import 'package:date_time_picker/date_time_picker.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:milk_duvet/models/customerDeliveries.dart';
import 'package:milk_duvet/models/customers.dart';
import 'package:intl/intl.dart';


import 'dbHelper.dart';
import 'domainAPI.dart';

class CustomerDeliveries extends StatefulWidget {
  const CustomerDeliveries({Key? key}) : super(key: key);

  @override
  State<CustomerDeliveries> createState() => _CustomerDeliveriesState();
}

class _CustomerDeliveriesState extends State<CustomerDeliveries> {
  List<CustDeliveries> deliveries = [];
  List<CustDeliveries> filterDeliveries = [];
  List<Customer> customers = [];
  final formater = NumberFormat("#,###", "en_US");

  var customerId;
  var loading = false;
  var isLoading = true;
  String? userId;
  String? token;

  TextEditingController quantityController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  Future<void> getUserInfo() async {
    var db = await DBHelper.instance.database;
    await db.rawQuery("select * from users").then((value) {
      value.forEach((element) {
        setState(() {
          userId = element['userId'].toString();
          token = element['token'].toString();
        });
      });
      fetchCustomers();
      fetchDeliveries();
    });
  }

  Future<void> fetchCustomers() async{
    Dio dio =Dio();
    var response = await dio.get("$myDomain/customers",
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'application/json',
        ));

    if(response.statusCode==200){
      var responses = response.data['customers'];
      setState(() {
        customers.clear();
        responses.forEach((element) {
          customers.add(Customer(
              id: element['id'].toString(),
              name: element['name'].toString(),
              telephone: element['telephone'].toString()
          ));
        });

      });
    }else{
      throw Exception("Failed to fetch");
    }
  }

  addMilkDelivery() async {

    var items = {
      'customer_id':customerId,
      'quantity':quantityController.text.trim(),
      'date_delivered':dateController.text.trim(),
    };
    var  options= BaseOptions(
      headers: {"Accept" : "application/json",'Authorization': 'Bearer $token'},
    );
    final Dio dio = Dio(options);
    try{
      final response = await dio.post(
        '$myDomain/deliveriestofactory',
        data: items,
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

  Future<void> fetchDeliveries() async{
    Dio dio =Dio();
    var response = await dio.get("$myDomain/mydeliveries",
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'application/json',
        ));

    if(response.statusCode==200){
      var responses = response.data['deliveries'];
      setState(() {
        filterDeliveries=deliveries;
        deliveries.clear();
        responses.forEach((element) {
          deliveries.add(CustDeliveries(
              id: element['id'].toString(),
              customerName: element['customer']['name'].toString(),
              quantity: element['quantity'].toString(),
              dateReceived: element['date_delivered'].toString(),

          ));
        });
        isLoading = false;

      });
    }else{
      throw Exception("Failed to fetch");
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("CUSTOMER DELIVERIES"),
        centerTitle: true,
        elevation: 0,
      ),
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
                  filterDeliveries = deliveries
                      .where((items) => (items.customerName
                      .toString()
                      .toLowerCase()
                      .contains(value.toLowerCase())) |(items.dateReceived
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
                    child: Text('Customer',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                Expanded(
                    flex: 2,
                    child: Text("Quantity(L)",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                Expanded(
                    flex: 2,
                    child: Text("Date",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),))
              ],
            ),
            const SizedBox(height: 10,),
            isLoading==false?Expanded(
              child: filterDeliveries.isNotEmpty?ListView.builder(
                  shrinkWrap: true,
                  itemCount: filterDeliveries.length,
                  itemBuilder: (context, index){
                    var items = filterDeliveries[index];
                    return Container(
                      color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      height: 50,
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text(items.customerName.toString())),
                          Expanded(
                              flex: 2,
                              child: Text(formater.format(int.parse(items.quantity.toString())))),
                          Expanded(
                              flex: 2,
                              child: Text(items.dateReceived.toString())),

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
                Text("Fetching Your Deliveries")
              ],
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: (){
            addDelivery();
          }, label: Row(
        children: const [
          Icon(Icons.add),
          SizedBox(width: 5,),
          Text("New Delivery"),
        ],
      )
      ),
    );
  }
  Future<void> addDelivery() async {
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
                      const Text("FILL IN THE MILK QTY FOR DELIVERY", style: TextStyle(fontWeight: FontWeight.bold),),
                      const Divider(height: 10, thickness: 1,),
                      const SizedBox(height: 10,),
                      DropdownSearch<Customer>(
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                        ),
                        items: customers,
                        itemAsString: (Customer item) =>
                            "${item.name.toString()} (${item.telephone.toString()})",
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15.0),
                              labelText: "Select Customer",
                              enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5))),
                        ),
                        onChanged: ((value) {
                          setState((){
                            customerId = value?.id;

                          });
                          // quantityController.text= value!.coolerQuantity.toString();
                        }),
                        validator: (value) {
                          if (value == null || value.id == '') {
                            return "Please choose a Customer ";
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
                                if (formKey.currentState!.validate()) {
                                  setState((){
                                    loading=true;
                                  });
                                  addMilkDelivery();
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
                Text('Delivery added successfully',
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

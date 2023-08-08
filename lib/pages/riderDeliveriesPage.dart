import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:milk_duvet/pages/domainAPI.dart';
import 'package:milk_duvet/widgets/drawer.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:intl/intl.dart';

import '../models/riderDeliveries.dart';
import 'dbHelper.dart';


class RiderDeliveriesPage extends StatefulWidget {
  const RiderDeliveriesPage({Key? key}) : super(key: key);

  @override
  State<RiderDeliveriesPage> createState() => _RiderDeliveriesPageState();
}

class _RiderDeliveriesPageState extends State<RiderDeliveriesPage> {
  var loading = false;
  var isLoading = true;
  var date;
  TextEditingController quantityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? coolerId;
  String? userId;
  String? token;
  var deliveries = [];

  Future<void> getUserInfo() async {
    var db = await DBHelper.instance.database;
    await db.rawQuery("select * from users").then((value) {
      value.forEach((element) {
        setState(() {
          coolerId = element['coolerId'].toString();
          userId = element['userId'].toString();
          token = element['token'].toString();
        });
      });
      fetchRideDeliveries();

    });
  }

  addStock() async {
    setState(() {
      loading= true;
    });
    var stockItems = {
      'quantity_picked':quantityController.text.trim(),
      'pickup_date':date,
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
          loading = false;
        });
      }else{
        Fluttertoast.showToast(msg: "Failed to Add");
        loading= false;
      }
    } on DioError catch(e){
    }
  }

  Future<void> fetchRideDeliveries() async{
    Dio dio =Dio();
    var response = await dio.get("$myDomain/mypickups",
      options: Options(
      headers: {'Authorization': 'Bearer $token'},
      contentType: 'application/json',
    ));
    if(response.statusCode==200){
      var responses = response.data['pickups'];
      setState(() {
        deliveries.clear();
        responses.forEach((element) {
          deliveries.add(RiderDeliveries(
            id: element['id'].toString(),
            coolerId: element['cooler']['name'].toString(),
            rideName: element['user']['name'].toString(),
            quantityPicked: element['quantity_picked'].toString(),
            pickedDate: element['pickup_date'].toString(),
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserInfo();
    date = DateFormat("yyyy-MM-d").format(DateTime.now());

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MY DELIVERIES"),
      ),
      drawer: const SideBar(),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 5),
        children: [
          Column(
            children: [
              const Text("The recent milk deliveries registered",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
              const SizedBox(height: 10,),
              isLoading==false? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: deliveries.length,
                  itemBuilder: (context, index){
                    var items = deliveries[index];
                    return Card(
                      elevation: 5,
                      color: Colors.grey[100],
                      child: ListTile(
                        leading: const Icon(Icons.hourglass_bottom_outlined,size: 30,color: Colors.blue,),
                        title: const Text('Quantity'),
                        subtitle: const Text("Date"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${items.quantityPicked} Litres"),
                            const SizedBox(height: 10,),
                            Text(items.pickedDate)
                          ],
                        ),
                      )
                    );

                  }
              ):Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:const [
                  Center(child: CircularProgressIndicator(),),
                  SizedBox(width: 10,),
                  Text("Fetching Deliveries")
                ],
              )

            ],
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: (){
            addMilkStock();
          },
          child: const Icon(Icons.add,color: Colors.white,),
      ),
    );
  }


  Future<void> addMilkStock() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
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
                    TextFormField(
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 15.0),
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
                      }
                      return null;
                      },
                    ),
                    const SizedBox(height: 20,),
                    DateTimePicker(
                    // controller: dateController,
                    type: DateTimePickerType.date,
                    dateMask: 'd MMM, yyyy',
                    initialValue: DateTime.now().toString(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    dateLabelText: 'Date',
                    selectableDayPredicate: (date) {
                      // Disable weekend days to select from the calendar
                      // if (date.weekday == 6 || date.weekday == 7) {
                      //   return true;
                      // }
                      return true;
                    },
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
                    onChanged: (val) {
                      date = val;
                    },
                    validator: (val) {
                      return null;
                    },
                    onSaved: (val) {
                      date = val;
                    },
                    ),
                    const SizedBox(height: 20,),
                    Row(

                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        loading== false?GestureDetector(
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              addStock();
                            }
                          },
                          child: Container(
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
                          ),
                        ):const Center(child: CircularProgressIndicator(),)
                      ],

                    )
                  ],

                ),
              ),
            ),
          ),
        );
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
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RiderDeliveriesPage()));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

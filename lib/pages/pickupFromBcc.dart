import 'package:date_time_picker/date_time_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';


import '../models/bccPickups.dart';
import 'dbHelper.dart';
import 'domainAPI.dart';

class DriverPickupsFromBCC extends StatefulWidget {
  const DriverPickupsFromBCC({Key? key}) : super(key: key);

  @override
  State<DriverPickupsFromBCC> createState() => _DriverPickupsFromBCCState();
}

class _DriverPickupsFromBCCState extends State<DriverPickupsFromBCC> {

  TextEditingController dateController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final formater = NumberFormat("#,###", "en_US");

  var loading = false;
  var isLoading = true;
  var updateLoading=false;

  List<AppPickups> pickups = [];
  List<AppPickups> filterPickups = [];
  List<InitiatedRequests> initiatedRequests = [];
  List<InitiatedRequests> filterInitiatedRequests = [];


  String? userId;
  String? token;
  var totalQuantity;


  Future<void> getUserInfo() async {
    var db = await DBHelper.instance.database;
    await db.rawQuery("select * from users").then((value) {
      value.forEach((element) {
        setState(() {
          userId = element['userId'].toString();
          token = element['token'].toString();
        });
      });
      fetchBccQty();
      fetchPickups();
      fetchInitiatedRequests();
    });
  }

  Future<void> fetchBccQty() async{
    Dio dio =Dio();
    try{
      var response = await dio.post("$myDomain/getbccqty",
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            contentType: 'application/json',
          ));

      if(response.statusCode==200){
        var responses = response.data;
        setState(() {
          totalQuantity = responses['Qty_balance'];
        });
      }else{
        throw Exception("Failed to fetch");
      }
    } on DioError catch(e){
      setState(() {
        loading=false;
      });

    }


  }

  requestPickup() async {
    var stockItems = {
      'quantity':quantityController.text.trim(),
      'date_picked':dateController.text.trim(),
    };
    var  options= BaseOptions(
      headers: {"Accept" : "application/json",'Authorization': 'Bearer $token'},
    );
    final Dio dio = Dio(options);
    try{
      final response = await dio.post(
        '$myDomain/pickuptofactory',
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

  Future<void> fetchPickups() async{
    Dio dio =Dio();
    try{
      var response = await dio.get("$myDomain/approved_pickups",
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            contentType: 'application/json',
          ));

      if(response.statusCode==200){
        var responses = response.data['pickups'];
        setState(() {
          filterPickups=pickups;
          pickups.clear();
          responses.forEach((element) {
            pickups.add(AppPickups(
              driverId: element['driver_id'].toString(),
              quantityPicked: element['quantity'].toString(),
              datePicked: element['date_picked'].toString(),

            ));
          });
          isLoading = false;

        });
      }else{
        throw Exception("Failed to fetch");
      }
    }on DioError catch(e){
      setState(() {
        loading=false;
      });

    }
  }

  Future<void> fetchInitiatedRequests() async{
    Dio dio =Dio();
    var response = await dio.get("$myDomain/pending_pickups",
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'application/json',
        ));

    if(response.statusCode==200){
      var responses = response.data['pickups'];
      setState(() {
        filterInitiatedRequests=initiatedRequests;
        initiatedRequests.clear();
        responses.forEach((element) {
          initiatedRequests.add(InitiatedRequests(
              id: element['id'].toString(),
              driverId: element['driver_id'].toString(),
              quantityPicked: element['quantity'].toString(),
              datePicked: element['date_picked'].toString(),
          ));
        });
        isLoading = false;

      });
    }else{
      throw Exception("Failed to fetch");
    }
  }

  updateRequest(var editedItem) async {
    var  options= BaseOptions(
      headers: {"Accept" : "application/json",'Authorization': 'Bearer $token'},
    );
    final Dio dio = Dio(options);
    try{
      final response = await dio.post(
        '$myDomain/editrequest',
        data: editedItem,
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

  deleteRequest(var items) async {
    var  options= BaseOptions(
      headers: {"Accept" : "application/json",'Authorization': 'Bearer $token'},
    );
    final Dio dio = Dio(options);
    try{
      final response = await dio.post(
        '$myDomain/removerequest',
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserInfo();
    dateController.text = DateFormat("yyyy-MM-dd").format(DateTime.now());

  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("BCC PICKUPS"),
            centerTitle: true,
            elevation: 0,
            bottom: const TabBar(
              tabs: [
                Tab(
                  text: "Approved Requests",
                ),
                Tab(text: "Initiated Requests"),
              ],
            ),

          ),
          body: TabBarView(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 5,vertical: 10),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "search by date",
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15.0),
                        border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10)),
                        suffixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filterPickups = pickups
                              .where((items) => (items.datePicked
                              .toString()
                              .toLowerCase()
                              .contains(value.toLowerCase())))
                              .toList();

                        });
                      },
                    ),
                    const SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Quantity(Ltrs)",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                        Text("Date",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)
                      ],
                    ),
                    const SizedBox(height: 10,),
                    isLoading==false? Expanded(
                      child: filterPickups.isNotEmpty?ListView.builder(
                          shrinkWrap: true,
                          itemCount: filterPickups.length,
                          itemBuilder: (context, index){
                            var items = filterPickups[index];
                            return Container(
                              color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              height: 50,
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [

                                  Text(formater.format(int.parse(items.quantityPicked.toString()))),
                                  Text(items.datePicked.toString()),
                                ],

                              ),
                            );

                          }
                      ):const Center(child: Text("NO DATA FOUND", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),),),
                    ):Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:const  [
                        CupertinoActivityIndicator(
                          radius: 20.0,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 5,),
                        Text("Fetching Pickups")
                      ],
                    ),
                  ],

                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10,horizontal: 5),
                child:Column(
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
                          filterInitiatedRequests = initiatedRequests
                              .where((items) =>(items.datePicked
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
                            child: Text('Quantity(L)',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                        Expanded(
                            flex: 3,
                            child: Text("Date",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                        Expanded(
                            flex: 2,
                            child: Text("Action",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),))
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Expanded(
                      child: filterInitiatedRequests.isNotEmpty?ListView.builder(
                          shrinkWrap: true,
                          itemCount: filterInitiatedRequests.length,
                          itemBuilder: (context, index){
                            var items = filterInitiatedRequests[index];
                            return Container(
                              color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              height: 50,
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 3,
                                      child: Text(formater.format(int.parse(items.quantityPicked.toString())))),
                                  Expanded(
                                      flex: 3,
                                      child: Text(items.datePicked.toString())),
                                  Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          GestureDetector(
                                              onTap: () {
                                                var item = {
                                                  'id':items.id,
                                                  'quantityPicked': items.quantityPicked,
                                                  'datePicked': items.datePicked,
                                                };
                                                editRequest(item);
                                              },
                                              child: const Icon(Icons.edit, color: Colors.blue,size: 25,)),
                                          GestureDetector(
                                            onTap: () {
                                              var item = {
                                                'id': items.id
                                              };
                                              showDeleteAlert(item);
                                            }
                                          ,child: const Icon(Icons.delete,color: Colors.red,size: 25,))
                                        ],
                                      )
                                  )
                                ],

                              ),
                            );

                          }
                      ):const Center(child: Text("NO DATA FOUND", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),),),
                    )
                ],
                ),
              )
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
              onPressed: (){
                addMilkPickup();
              },

              label: Row(
                children: const [
                  Icon(Icons.add),
                  SizedBox(width: 5,),
                  Text("New Request"),
                ],
              )
          ),
        )
    );

  }
  Future<void> addMilkPickup() async {
    var bccTotalQuantity = totalQuantity;
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
                                  if(int.parse(quantityController.text.toString().replaceAll(",", ""))>int.parse(bccTotalQuantity.toString())){
                                    showLessQtyAlert(bccTotalQuantity.toString());

                                  } else{
                                    requestPickup();
                                    setState((){
                                      loading=true;
                                    });
                                  }
                                }
                              },
                              child: loading==false? Container(
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
                Text('Request has been sent to the BCC for approval',
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
                  fetchInitiatedRequests();
                  fetchPickups();
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
  Future<void> showLessQtyAlert(String bccTotalQty) async {

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
                Text("The milk quantity ${quantityController.text.toString()} requested is greater than the available milk stock ${bccTotalQty.toString()}",
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
                  fetchInitiatedRequests();
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

  Future<void> editRequest(var item) async {
    String id = item['id'];
    dateController.text = item['datePicked'];
    quantityController.text  = item['quantityPicked'];
    var bccTotalQuantity = totalQuantity;

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
                      const Text("EDIT THE MILK QTY FOR PICKUP", style: TextStyle(fontWeight: FontWeight.bold),),
                      const Divider(height: 10, thickness: 1,),
                      const SizedBox(height: 10,),

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
                              Navigator.pop(context);
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
                                  if(int.parse(quantityController.text.toString().replaceAll(",", ""))>int.parse(bccTotalQuantity.toString())){
                                    showLessQtyAlert(bccTotalQuantity.toString());

                                  } else{
                                    var editedItems = {
                                      'id': id,
                                      'quantity':quantityController.text.trim(),
                                      'date_picked':dateController.text.trim(),
                                    };
                                    updateRequest(editedItems);
                                    setState((){
                                      updateLoading = true;
                                    });
                                  }
                                }
                              },
                              child: updateLoading==false? Container(
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
                  fetchInitiatedRequests();
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
                    deleteRequest(items);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }


}

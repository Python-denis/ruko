import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:milk_duvet/models/dispatches.dart';

import 'dbHelper.dart';
import 'domainAPI.dart';

class Dispatches extends StatefulWidget {
  const Dispatches({Key? key}) : super(key: key);

  @override
  State<Dispatches> createState() => _DispatchesState();
}

class _DispatchesState extends State<Dispatches> {
  List<DispatchesMade> dispatches = [];
  List<DispatchesMade> filterDispatches = [];
  final formater = NumberFormat("#,###", "en_US");


  var isLoading = true;

  String? token;
  String? userId;
  Future<void> getUserInfo() async {
    var db = await DBHelper.instance.database;
    await db.rawQuery("select * from users").then((value) {
      for (var element in value) {
        setState(() {
          userId = element['userId'].toString();
          token = element['token'].toString();
        });
      }
      fetchDispatches();
    });
  }

  Future<void> fetchDispatches() async{
    Dio dio =Dio();
    try {
      var response = await dio.get("$myDomain/mydispatches",
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            contentType: 'application/json',
          ));

      if (response.statusCode == 200) {
        var responses = response.data;

        setState(() {
          filterDispatches = dispatches;
          dispatches.clear();
          responses.forEach((element) {
            dispatches.add(DispatchesMade(
              id: element['id'].toString(),
              driverName: element['driver'].toString(),
              quantity: element['quantity_picked'].toString(),
              datePicked: element['date_picked'].toString(),
            ));
          });
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch");
      }
    }on DioError catch(e){
      print(e.response);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserInfo();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DISPATCHES"),
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
                  filterDispatches = dispatches
                      .where((items) => (items.driverName
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
                    child: Text('Driver',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                Expanded(
                    flex: 2,
                    child: Text("Qty(L)",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                Expanded(
                    flex: 2,
                    child: Text("Date",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),))
              ],
            ),
            const SizedBox(height: 10,),
            isLoading==false?Expanded(
              child: filterDispatches.isNotEmpty?ListView.builder(
                  shrinkWrap: true,
                  itemCount: filterDispatches.length,
                  itemBuilder: (context, index){
                    var items = filterDispatches[index];
                    return Container(
                      color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      height: 50,
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text(items.driverName.toString())),
                          Expanded(
                              flex: 2,
                              child: Text(formater.format(int.parse(items.quantity.toString())))),
                          Expanded(
                              flex: 2,
                              child: Text(items.datePicked.toString())),

                        ],

                      ),
                    );

                  }
              ):const Center(child: Text("NO DISPATCHES FOUND", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),),),
            ):Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CupertinoActivityIndicator(
                  radius: 20.0,
                  color: Colors.blue,
                ),
                SizedBox(width: 10,),
                Text("Fetching dispatches")
              ],
            )
          ],
        ),
      )

    );
  }
}

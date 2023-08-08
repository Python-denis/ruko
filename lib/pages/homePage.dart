import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';
import 'package:milk_duvet/pages/domainAPI.dart';
import 'package:milk_duvet/pages/todaysCollection.dart';
import 'package:milk_duvet/pages/unconfirmedPickups.dart';
import 'package:milk_duvet/widgets/drawer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';


import 'dbHelper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  var totalQuantity;
  var todaysCollection;
  var loading = true;
  var unconfirmedPickups;
  var totalDelivered;
  var totalDel;
  final formater = NumberFormat("#,###", "en_US");


  // graph data
  final List<_ChartData> _chartData = [

  ];

  String? userId;
  String? token;
  String? coolerName;
  Future<void> getUserInfo() async {
    var db = await DBHelper.instance.database;
    await db.rawQuery("select * from users").then((value) {
      value.forEach((element) {
        setState(() {
          userId = element['userId'].toString();
          token = element['token'].toString();
          coolerName = element['coolerName'].toString();
        });
      });
      fetchDashboardItems();
    });
  }


  Future<void> fetchDashboardItems() async{
    var  options= BaseOptions(
        headers: {"Accept" : "application/json",'Authorization': 'Bearer $token',

        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10)
    );

    final Dio dio = Dio(options);
    try{
      var response = await dio.get("$myDomain/dashboard");
      if(response.statusCode==200){
        var responses = response.data;
        setState(() {
          totalQuantity = responses['total']['total_collection'] ?? 0;
          todaysCollection = responses['today']['total_qty'] ?? 0;
          unconfirmedPickups = responses['count'] ?? 0;
          totalDel=responses['countDelivered']['total_delivered'];

          // check for null values, if null is present, equate totalDel to zero, as shown below in the variable totalDelivered
          totalDelivered = totalDel ?? 0;

          // String dateString = responses['today']['date'] ?? 0;
          // DateTime dateTime = DateFormat("yyyy-MM-dd").parseStrict(dateString);

          String dateString = responses['today']['date'];
          DateTime dateTime = DateFormat("yyyy-MM-dd").parseStrict(dateString);
          String today = DateFormat("E").format(dateTime);

          // String today = DateFormat("yyyy-MM-dd").parseStrict(dateString).toString();
          // String today = DateFormat("E").format(DateTime.parse(responses['today']['date']));
          String yest = DateFormat("E").format(DateTime.parse(responses['yesterday']['date']));
          String lasttwo = DateFormat("E").format(DateTime.parse(responses['lasttwo']['date']));
          String lasthree = DateFormat("E").format(DateTime.parse(responses['lassthree']['date']));
          String lastfour = DateFormat("E").format(DateTime.parse(responses['lastfou']['date']));
          String lastfive = DateFormat("E").format(DateTime.parse(responses['lastfive']['date']));


          _chartData.add(_ChartData(today, double.parse(responses['today']['total_qty'] ?? 0) ));
          _chartData.add(_ChartData(yest, double.parse(responses['yesterday']['total_qty'] ?? 0) ));
          _chartData.add(_ChartData(lasttwo, double.parse(responses['lasttwo']['total_qty'] ?? 0) ));
          _chartData.add(_ChartData(lasthree, double.parse(responses['lassthree']['total_qty'] ?? 0) ));
          _chartData.add(_ChartData(lastfour, double.parse(responses['lastfou']['total_qty'] ?? 0) ));
          _chartData.add(_ChartData(lastfive, double.parse(responses['lastfive']['total_qty'] ?? 0) ));
          // _chartData.add(_ChartData("1st Day", double.parse(responses['lastsix']['total_qty'] ?? 0) ));
          loading = false;
        });
      }else{
        throw Exception("Failed to fetch");
      }
    } on DioError catch(e){
      loading = false;

    }

  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserInfo();
    Timer.periodic(const Duration(seconds: 2), (timer) {
      fetchDashboardItems();
    });
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showExitDialogue();
        return true; // Return true to allow the back button press to be handled
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("RUKO MILK-DASHBOARD",style: TextStyle(fontSize: 18),),
          elevation: 0,
        ),
        drawer: const SideBar(),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 13),
          children: [
            loading==false?Column(
              children: [
                Text("$coolerName",style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
                const SizedBox(height: 15,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {

                        },
                        child: Card(
                          elevation: 5,
                          child: Container(
                            height: 130,
                            width: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children:  [
                                    const Text(
                                      "QUANTITY IN STOCK",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight:
                                          FontWeight.bold),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                        "${formater.format((int.parse(totalQuantity.toString())-int.parse(totalDelivered.toString()))).toString()} Litres",
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight:
                                            FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                        child: GestureDetector(
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>const TodaysCollection()));
                          },
                          child: Card(
                            elevation: 5,
                            child: Container(
                              height: 130,
                              width: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children:   [
                                      const Text(
                                        "TODAY'S COLLECTION",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                          formater.format(int.parse(todaysCollection.toString())),
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight:
                                              FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),)
                    ),

                  ],
                ),
                GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>const UnconfirmedPickups()));
                  },
                  child: Card(
                    elevation: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      height: 90,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "UNCONFIRMED PICKUPS",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight:
                                FontWeight.bold),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          CircleAvatar(
                            child: Text(
                                unconfirmedPickups.toString(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                    FontWeight.bold,fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15,),
                const Text("Total Litres of milk recorded over last six days", style: TextStyle(fontWeight: FontWeight.w600,fontSize: 16),),
                const SizedBox(height: 15,),
                Center(
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    series: <ChartSeries<_ChartData, String>>[
                      ColumnSeries<_ChartData, String>(
                        dataSource: _chartData,
                        xValueMapper: (_ChartData data, _) => data.month,
                        yValueMapper: (_ChartData data, _) => data.value,
                      ),
                    ],
                  ),
                )

              ],
            )
                :Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
               CupertinoActivityIndicator(
                radius: 20.0,
                color: Colors.blue,
              ),
                SizedBox(width: 10,),
                Text("Fetching dashboard items")
              ],
            )
          ],
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


}
class _ChartData {
  final String month;
  final double value;
  _ChartData(this.month, this.value);

}

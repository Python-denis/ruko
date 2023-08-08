import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:milk_duvet/models/pickups.dart';
import 'package:milk_duvet/pages/domainAPI.dart';
import 'package:milk_duvet/widgets/drawer.dart';
import 'package:intl/intl.dart';


import 'dbHelper.dart';

class UnconfirmedPickups extends StatefulWidget {
  const UnconfirmedPickups({Key? key}) : super(key: key);

  @override
  State<UnconfirmedPickups> createState() => _UnconfirmedPickupsState();
}

class _UnconfirmedPickupsState extends State<UnconfirmedPickups> {
  List<Pickups> pickups = [];
  List<Pickups> filterPickups = [];
  final formater = NumberFormat("#,###", "en_US");

  var userId;
  var token;
  var isLoading =true;

  Future<void> getUserInfo() async {
    var db = await DBHelper.instance.database;
    await db.rawQuery("select * from users").then((value) {
      value.forEach((element) {
        setState(() {
          userId = element['userId'].toString();
          token = element['token'].toString();
        });
      });

      fetchPickups();
    });
  }

  Future<void> fetchPickups() async{
    Dio dio =Dio();
    var response = await dio.get("$myDomain/cooler_deliveries",
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'application/json',
        ));

    if(response.statusCode==200){
      var responses = response.data;
      setState(() {
        filterPickups=pickups;
        pickups.clear();
        responses.forEach((element) {
          pickups.add(Pickups(
            id: element['id'].toString(),
              quantityPicked: element['quantity_picked'].toString(),
              datePicked: element['date_picked'].toString(),
              coolerName: element['cooler'].toString(),
              driverName: element['driver'].toString(),

          ));
        });
        isLoading = false;

      });
    }else{
      throw Exception("Failed to fetch");
    }
  }

  Future<void> updatePickups(String id) async{
    Dio dio =Dio();
    var response = await dio.get("$myDomain/updatepk/$id",
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'application/json',
        ));

    if(response.statusCode==200){
      showSuccess();
      fetchPickups();

    }else{
      throw Exception("Failed to fetch");

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
        title: const Text("UNCONFIRMED PICKUPS"),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: const SideBar(),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),

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
                  filterPickups = pickups
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
                    flex: 3,
                    child: Text("Quantity",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                Expanded(
                    flex: 2,
                    child: Text("Action",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),))
              ],
            ),
            const SizedBox(height: 10,),
            isLoading==false?Expanded(
                child: filterPickups.isNotEmpty? ListView.builder(
                    shrinkWrap: true,
                    itemCount: filterPickups.length,
                    itemBuilder: (context, index){
                      var items = filterPickups[index];
                      return Container(
                        color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        height: 60,
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text("${items.driverName}")),
                            Expanded(
                                flex: 3,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${formater.format(int.parse(items.quantityPicked.toString()))} ltrs"),
                                    Text("On ${items.datePicked}")
                                  ],
                                )),
                             Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: (){
                                    showUpdateAlert(items.id.toString());
                                  },
                                  child: Container(
                                    height: 30,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Colors.blue
                                    ),
                                    child: const Center(child: Text("Confirm", style: TextStyle(color: Colors.white),),),
                                  ),
                                )
                            )
                          ],

                        ),
                      );

                    }
                ):const Center(child: Text("NO PICKUPS FOUND", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),),)
            ):Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:const [
                Center(child: CircularProgressIndicator(),),
                SizedBox(width: 10,),
                Text("Fetching the pickups"),
              ],
            )

          ],
        ),
      ),
    );
  }
  Future<void> showUpdateAlert(String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 60.0,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text('Are sure you want to confirm this pickup?', textAlign: TextAlign.center),
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
                        color: Colors.blue,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w900),
                  ),
                  onPressed: () {
                    updatePickups(id);
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

  Future<void> showSuccess() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState){
          return AlertDialog(
            title: const Icon(
              Icons.check_circle_outline,
              color: Colors.blue,
              size: 60.0,
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: const [
                  Text('Pickup Confirmed Successfully',
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
                    Navigator.pop(context);

                  },
                ),
              ),
            ],
          );
        });
      },
    );
  }
}

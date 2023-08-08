import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:milk_duvet/pages/domainAPI.dart';
import 'package:intl/intl.dart';


import '../models/deliveries.dart';
import 'dbHelper.dart';

class TodaysCollection extends StatefulWidget {
  const TodaysCollection({Key? key}) : super(key: key);

  @override
  State<TodaysCollection> createState() => _TodaysCollectionState();
}

class _TodaysCollectionState extends State<TodaysCollection> {

  String? token;
  String? userId;
  var todaysCollection = [];
  var filtertodaysCollection = [];
  var isLoading= true;
  final formater = NumberFormat("#,###", "en_US");


  Future<void> getUserInfo() async {
    var db = await DBHelper.instance.database;
    await db.rawQuery("select * from users").then((value) {
      for (var element in value) {
        setState(() {
          userId = element['userId'].toString();
          token = element['token'].toString();
        });
      }
      fetchtodaysCollection();
    });
  }

  Future<void> fetchtodaysCollection() async{
    Dio dio =Dio();
    var response = await dio.get("$myDomain/todaysCollection",
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'application/json',
        ));

    if(response.statusCode==200){
      var responses = response.data['pickups'];
      setState(() {
        filtertodaysCollection = todaysCollection;
        todaysCollection.clear();
        responses.forEach((element) {
          todaysCollection.add(Deliveries(
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
        title: const Text("TODAY'S MILK COLLECTION"),
        centerTitle: true,
      ),
      body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5,vertical: 10),
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
                  filtertodaysCollection = todaysCollection
                      .where((items) => (items.rideName
                      .toString()
                      .toLowerCase()
                      .contains(value.toLowerCase())) | (items.dateReceived
                      .toString()
                      .toLowerCase()
                      .contains(value.toLowerCase())))
                      .toList();
                  // searchString = value;
                  // snapshot.hasData
                });
              },
            ),
            const SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Expanded(
                    flex: 3,
                    child: Text('Rider',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),)),
                Expanded(
                    flex: 3,
                    child: Text("Quantity(Ltr)",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                Expanded(
                    flex: 2,
                    child: Text("Date",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),))
              ],
            ),
            const SizedBox(height: 10,),
            isLoading==false? Expanded(
              child: filtertodaysCollection.isNotEmpty? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtertodaysCollection.length,
                  itemBuilder: (context, index){
                    var items = filtertodaysCollection[index];
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
              ):const Center(child: Text("NO COLLECTIONS AVAILABLE ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),),)
            ):Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:const [
                Center(child: CircularProgressIndicator(),),
                SizedBox(width: 10,),
                Text("Fetching Today's Collections")
              ],
            )
          ],
        ),
      ),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/riders.dart';
import 'dbHelper.dart';
import 'domainAPI.dart';

class AllRiders extends StatefulWidget {
  const AllRiders({Key? key}) : super(key: key);

  @override
  State<AllRiders> createState() => _AllRidersState();
}

class _AllRidersState extends State<AllRiders> {

  String? token;
  String? coolerId;
  String? userId;
  List<Rider> riders = [];
  List<Rider> filterRiders = [];
  var isLoading = true;

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
      fetchRiders();
    });
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
        filterRiders = riders;
        riders.clear();
        responses.forEach((element) {
          riders.add(Rider(
            rideName: element['full_name'],
            phone: element['contact']
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
        title: const Text("FARMERS"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: "search by name and contact",
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 15.0),
                border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10)),
                suffixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  filterRiders = riders
                      .where((items) => (items.rideName
                      .toString()
                      .toLowerCase()
                      .contains(value.toLowerCase())) | (items.phone
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
                    child: Text('Farmer`s Name',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),)),
                Expanded(
                    flex: 3,
                    child: Text("Contact",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),))
              ],
            ),
            const SizedBox(height: 10,),
            isLoading==false?
            Expanded(
                child: filterRiders.isNotEmpty? ListView.builder(
                    shrinkWrap: true,
                    itemCount: filterRiders.length,
                    itemBuilder: (context, index){
                      var items = filterRiders[index];
                      return Container(
                        color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        height: 50,
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text(items.rideName.toString())),
                            Expanded(
                                flex: 3,
                                child: Text(items.phone.toString()))
                          ],

                        ),
                      );

                    }
                )
                    :const Center(child: Text("NO DATA FOUND", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),),)
            ):Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Center(child: CircularProgressIndicator(),),
                SizedBox(width: 10,),
                Text("Fetching Farmers")
              ],
            )
          ],
        ),
      ),
    );
  }
}

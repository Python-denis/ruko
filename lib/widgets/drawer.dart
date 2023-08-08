import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:milk_duvet/pages/all_deliveries.dart';
import 'package:milk_duvet/pages/allRiders.dart';
import 'package:milk_duvet/pages/customerDeliveries.dart';
import 'package:milk_duvet/pages/dispathes.dart';
import 'package:milk_duvet/pages/driverPickups.dart';
import 'package:milk_duvet/pages/homePage.dart';
import 'package:milk_duvet/pages/profile.dart';
import 'package:milk_duvet/pages/riderDeliveriesPage.dart';
import '../pages/dbHelper.dart';
import '../pages/loginPage.dart';
import '../pages/pickupFromBcc.dart';


class SideBar extends StatefulWidget {
  const SideBar({Key? key}) : super(key: key);

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {

  String? fullname;
  String? coolerName;
  String? role;
  Future<void> getUserInfo() async {
    var db = await DBHelper.instance.database;
    await db.rawQuery("select * from users").then((value) {
      value.forEach((element) {
        setState(() {
          fullname = element['fullname'].toString();
          coolerName = element['coolerName'].toString();
          role = element['role'].toString();
        });
      });

    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserInfo();
  }
  @override
  Widget build(BuildContext context) {
    return  SafeArea(
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$coolerName',
                        style:const TextStyle(
                            color: Colors.white,
                            fontSize: 25.0,
                            fontWeight: FontWeight.w800),
                      ),
                      Text(
                        "$fullname",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800,fontSize: 20),
                      )
                    ],
                  )),
            ),
            role=='Manager'?
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const HomePage()));
              },
            ):const SizedBox(),
            role=='Manager'?
            ListTile(
              leading: const Icon(Icons.delivery_dining_outlined),
              title: const Text('All Deliveries'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AllDeliveries()));
              },
            ):const SizedBox(),
            role=='Manager'?
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Dispatches'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const Dispatches()));
              },
            ):const SizedBox(),
            role=='Manager'?
            ListTile(
              leading: const Icon(Icons.directions_bike),
              title: const Text('Farmers'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const AllRiders()));
              },
            ):const SizedBox(),
            role=='Rider'?
            ListTile(
              leading: const Icon(Icons.delivery_dining_outlined),
              title: const Text('Deliveries'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RiderDeliveriesPage()));
              },
            ):const SizedBox(),
            role=='Driver'? ExpansionTile(title: Row(
              children: const [
                Icon(Icons.local_shipping_outlined),
                SizedBox(width: 32,),
                Text("Pickups"),
              ],

            ),
              children: [
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: const Text("Pickups From MCC"),
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>const DriverPickups()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: const Text("Pickups From BCC"),
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>const DriverPickupsFromBCC()));
                  },
                ),
              ],
            ):const SizedBox(),
            role=='Driver'?ListTile(
              leading: const Icon(Icons.local_shipping_sharp),
              title: const Text('Deliveries to Customers'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const CustomerDeliveries()));
              },
            ):const SizedBox(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const ProfilePage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('LogOut'),
              onTap: () {
                logoutUser();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  Future<void> logoutUser() async {
    var db = await DBHelper.instance.database;
    db.delete("users").then((value) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    });
  }
}

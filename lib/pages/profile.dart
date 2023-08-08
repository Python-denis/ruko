import 'package:flutter/material.dart';

import 'dbHelper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  String? userId;
  String? token;
  String? fullName;
  String? userName;
  String? email;
  String? role;
  String? contact;
  Future<void> getUserInfo() async {
    var db = await DBHelper.instance.database;
    await db.rawQuery("select * from users").then((value) {
      value.forEach((element) {
        setState(() {
          userId = element['userId'].toString();
          token = element['token'].toString();
          fullName = element['fullname'].toString();
          userName = element['username'].toString();
          email = element['email'].toString();
          role = element['role'].toString();
          contact = element['contact'].toString();
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("MY PROFILE"),
        elevation: 0,
      ),
      body: ListView(
        children: [
          Column(
            children: [
              Container(
                height: 180,
                width: MediaQuery.of(context).size.width,
                decoration:  BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius:  const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(child: Text("$fullName"[0],style: const TextStyle(fontSize: 20),),),
                    Text("$userName", style: const TextStyle(fontWeight: FontWeight.w800,fontSize: 30,color: Colors.white),)
                  ],
                ),
              ),
              const SizedBox(height: 20,),
              const Text("PERSONAL INFORMATION"),
              const Divider(height: 10,),
              ListTile(
                leading: const Text("Fullname"),
                trailing: Text("$fullName"),
              ),
              const Divider(height: 10,),
              ListTile(
                leading: const Text("Email"),
                trailing: email != 'null'
              ? Text('$email')
            : const Text("No Email Added"),
              ),
              const Divider(height: 10,),
              ListTile(
                leading: const Text("Contact"),
                trailing: contact!='null'?Text("$contact"):const Text("No Contact Added"),
              ),
              const Divider(height: 10,),
              ListTile(
                leading: const Text("Role"),
                trailing: Text("$role"),
              ),
            ],
          )
        ],
      ),
    );
  }
}

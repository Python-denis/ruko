import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:milk_duvet/pages/domainAPI.dart';
import 'package:milk_duvet/pages/driverPickups.dart';
import 'package:milk_duvet/pages/riderDeliveriesPage.dart';

import 'dbHelper.dart';
import 'homePage.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool tooglevisibility = true;
  var loading = false;

  final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  loginUser() async {
    setState(() {
      loading =true;
    });
    var items = {
      'username':usernameController.text.trim(),
      'password':passwordController.text.trim()
    };

    Dio dio =Dio();
    try {
      var response = await dio.post(
        '$myDomain/login',
        data: items,
        options: Options(
          headers: {'Authorization': 'Bearer token'},
        // receiveTimeout: Duration(seconds: 5),
        //   sendTimeout: Duration(seconds: 5),
        ),
      );
      if(response.statusCode==200){
        var result = response.data;

        var myData = {
          'userId':result['user']['id'],
          'username':result['user']['username'],
          'fullname':result['user']['full_name'],
          'email':result['user']['email'],
          'coolerName':result['user']['cooler_name'],
          'role':result['user']['role_name'],
          'token':result['token'],
          'coolerId':result['user']['cooler_id'],
          'contact':result['user']['contact']

        };
        setState(() {
          loading=false;
        });
      var db = await DBHelper.instance.database;
      db.delete(DBHelper.users).then((value) async => {
       await db.insert(DBHelper.users, myData).then((value) {})
      });
        Future.delayed(const Duration(seconds: 2), (() {
          if(myData["role"] == "Manager"){
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const HomePage()));
          }else if(myData["role"] == "Rider"){
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const RiderDeliveriesPage()));
          }else if(myData["role"] == "Driver"){
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const DriverPickups()));
          }

        }));
      }else if(response.statusCode==202){
        showLoginError();
        setState(() {
          loading = false;

        });
      }

    } catch (error) {
      setState(() {
        loading=false;
      });
    }

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // loggedInUser();
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async {
        showExitDialogue();
        return true; // Return true to allow the back button press to be handled
      },
      child:Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              color: Colors.blue,
              // margin: const EdgeInsets.symmetric(vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      height: 200.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:  [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: const SizedBox(height:100,width:180,child: Image(image: AssetImage("assets/logo2.png"),fit: BoxFit.cover,))
                          ),
                          const Text("WELCOME BACK TO RUKO MILK", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18.0),),

                        ],
                      ),

                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50),
                          topRight: Radius.circular(50),),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 50.0,),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 15.0),
                                labelText: 'Username',
                                suffixIcon: const Icon(Icons.person),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              controller: usernameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Username cannot be empty";
                                }
                                return null;
                              },
                            ),
                          ),

                          SizedBox(height: 30,),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 15.0),
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  onPressed: (){
                                    setState(() {
                                      tooglevisibility = !tooglevisibility;

                                    });
                                  },
                                  icon: tooglevisibility? const Icon(Icons.visibility_off): const Icon(Icons.visibility),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              obscureText: tooglevisibility,
                              controller: passwordController,
                              validator:  (value) {
                                if (value == null || value.isEmpty) {
                                  return "Password cannot be empty";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 40,),
                          GestureDetector(
                            onTap: (){
                              if (_formKey.currentState!.validate()) {
                                loginUser();
                              }
                            },
                            child: loading==false? Container(
                              margin: const EdgeInsets.symmetric(horizontal: 15),
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                                color: Colors.blue,
                              ),
                              child: const Center(child: Text("LOGIN",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20.0))),
                            ): const Center(
                              child:  CupertinoActivityIndicator(
                                radius: 25.0,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Powered By"),
                              const SizedBox(width: 3,),
                              TextButton(onPressed: (){},
                                  child: const Text("Nugsoft Technologies"))
                            ],
                          )
                          ],
                          
                      ),

                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      )
    );

  }
  Future<void> showLoginError() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            height: 100,
            color: Colors.grey,
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60.0,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text('Wrong Credentials, Please try again',
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
                      color: Colors.red,
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

  // loggedInUser() async {
  //   var db = await DBHelper.instance.database;
  //   // db?.query(DBHelper.users).then((value) {});
  //
  //   await db.query("users").then((value) {
  //     if (value.isNotEmpty && value[0]['role']=='Manager') {
  //       Navigator.pushReplacement(
  //           context, MaterialPageRoute(builder: (context) => const HomePage()));
  //     }else if(value.isNotEmpty && value[0]['role']=='Driver'){
  //       Navigator.pushReplacement(
  //           context, MaterialPageRoute(builder: (context) => const DriverPickups()));
  //     }
  //   });
  // }


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
                Text('Are you sure you want to exit from the application',
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


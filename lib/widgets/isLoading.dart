import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:milk_duvet/pages/homePage.dart';
import 'package:milk_duvet/pages/riderDeliveriesPage.dart';
import '../pages/loginPage.dart';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  Widget myLoader() {
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
    return  Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: const SizedBox(height:100,width:180,child: Image(image: AssetImage("assets/logo.png"),fit: BoxFit.cover,))
            ),
            const SizedBox(height: 10,),
            const CupertinoActivityIndicator(
              radius: 25.0,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return myLoader();
  }
}


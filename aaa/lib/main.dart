import 'package:aaa/admin/admin_home.dart';
// import 'package:aaa/login_sreen.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Управление ключами',
      theme: ThemeData(
        fontFamily: 'Inter',
        primarySwatch: Colors.blue,
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
       home: AdminHome(),
    );
  }
}

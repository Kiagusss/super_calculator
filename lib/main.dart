import 'package:flutter/material.dart';
import 'package:easy_scaffold/easy_scaffold.dart';
import 'package:super_calculator/pages/main_calculator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      color: Colors.black,
      home: Scaffold(
        backgroundColor: colorWhite,
        body: const CalculatorScreen(),
      ),
    );
  }
}

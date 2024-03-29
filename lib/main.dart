import 'package:flutter/material.dart';
import 'package:easy_scaffold/easy_scaffold.dart';
import 'package:super_calculator/pages/main_calculator.dart';
import 'package:provider/provider.dart';
import 'package:super_calculator/theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<ThemeProvider>(context, listen: false)
          .loadThemePreference(),
      builder: (context, snapshot) {
        return MaterialApp(
          theme: Provider.of<ThemeProvider>(context).themeData,
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          color: Colors.black,
          home: Scaffold(
            backgroundColor: colorWhite,
            body: const CalculatorScreen(),
          ),
        );
      },
    );
  }
}

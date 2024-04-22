import 'package:easy_scaffold/easy_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:super_calculator/pages/unit_page/length.dart';
import 'package:super_calculator/pages/unit_page/temperature.dart';
import 'package:super_calculator/pages/unit_page/time.dart';
import 'package:super_calculator/pages/unit_page/volume.dart';
import 'package:super_calculator/pages/unit_page/weight.dart';

class UnitPage extends StatefulWidget {
  const UnitPage({super.key});

  @override
  State<UnitPage> createState() => _UnitPageState();
}

class _UnitPageState extends State<UnitPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              indicatorColor: Theme.of(context).colorScheme.secondary,
              labelColor: Theme.of(context).colorScheme.secondary,
              isScrollable: true,
              tabs: const [
                Tab(
                  text: "Length",
                ),
                Tab(
                  text: "Volume",
                ),
                Tab(
                  text: "Temperature",
                ),
                Tab(
                  text: "Time",
                ),
                Tab(
                  text: "Weight",
                ),
              ],
            ),
            title: const Text(
              'Unit Converter',
              style: TextStyle(fontSize: 20),
            ),
            leading: InkWell(
                onTap: () {
                  backPage(context);
                },
                child: const Icon(
                  Icons.arrow_back_ios,
                )),
          ),
          body: const TabBarView(
            children: [
              LengthPage(),
              VolumePage(),
              TemperaturePage(),
              TimePage(),
              WeightPage(),
            ],
          ),
        ),
      ),
    );
  }
}

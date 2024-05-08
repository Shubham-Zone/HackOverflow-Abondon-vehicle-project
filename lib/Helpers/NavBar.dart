import 'package:abondon_vehicle/Pages/CriminalCars.dart';
import 'package:abondon_vehicle/Pages/Reports.dart';
import 'package:abondon_vehicle/Pages/Rto_Admin.dart';
import 'package:flutter/material.dart';

import '../Mongodb/UserData.dart';

class NavBar extends StatefulWidget {

  final int idx;

  const NavBar({super.key, required this.idx});

  @override
  State<NavBar> createState() => _NavBarState();

}

class _NavBarState extends State<NavBar> {

  late int index;

  // List of pages
  List pages = [
    const CriminalCars(),
    const Reports()

  ];

  @override
  void initState() {
    index = widget.idx;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Colors.teal.withOpacity(0.7),
        ), child: NavigationBar(
        selectedIndex: index,
        elevation: 8,
        height: MediaQuery.of(context).size.height * 0.085,
        onDestinationSelected: (index) =>
            setState(()=> this.index = index),
        destinations:const [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
        ],
      ),
      ),
    );
  }
}

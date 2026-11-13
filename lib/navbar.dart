
import 'package:flutter/material.dart';
import 'package:islamicapp/home.dart';
import 'package:islamicapp/prayer.dart';
import 'package:islamicapp/qibla.dart';
import 'package:islamicapp/setting.dart';
import 'package:nav_bar/nav_bar.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int pages = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [      
      const AllahNames(),
        prayertime(),
      QiblaScreen(),
      Setting()
     ];

    return Scaffold(
      body: screens[pages],

      bottomNavigationBar: FuturisticNavBar(
        selectedIndex: pages,
      
        onItemSelected: (i) {
          setState(() {
            pages = i;
          });
        },
      
        style: NavBarStyle.synapse,
        theme: FuturisticTheme.cyberpunk(),
        iconAnimationType: IconAnimationType.fade,
        showGlow: false,
      
        items:   [
          NavBarItem(
            icon: Icons.home,
            label: 'Home',
          ),
          NavBarItem(
            icon: Icons.timer,
            label: 'Prayer',
          ),
           NavBarItem(
            icon: Icons.compass_calibration_sharp,
            label: 'Qibla',
          ),
           NavBarItem(
            icon: Icons.settings,
            label: 'Setting',
          ),            
        ],
      ),
    );
  }
} 

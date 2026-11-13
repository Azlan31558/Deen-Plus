
import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {

  int count = 0;
  int streak = 1;

  String selectedTasbeeh = 'Subhan Allah';

  final List<Map<String, String>> tasbeehList = [
    {
      'name': 'Subhan Allah',
      'arabic': 'سُبْحَانَ اللَّهِ',
    },
    {
      'name': 'Alhamdulillah',
      'arabic': 'الْحَمْدُ لِلَّهِ',
    },
    {
      'name': 'Allahu Akbar',
      'arabic': 'اللَّهُ أَكْبَرُ',
    },
    {
      'name': 'Astaghfirullah',
      'arabic': 'أَسْتَغْفِرُ اللَّهَ',
    },
    {
      'name': 'La ilaha illallah',
      'arabic': 'لَا إِلَٰهَ إِلَّا اللَّهُ',
    },
    {
      'name': 'Darood Shareef',
      'arabic': 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
    },
    {
      'name': 'La Hawla Wala Quwwata',
      'arabic': 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    },
  ];

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;

    final counterSize = screenWidth * 0.76;

    return Scaffold(

                     backgroundColor: Colors.teal,



      body: Container(

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff002e2b),
              Colors.teal,
              Colors.teal,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(

          child: SingleChildScrollView(

            child: Column(
              children: [

                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),

                  child: Row(
                    children: [

                      // Back Button
                      Container(
                        height: 48,
                        width: 48,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(
                            color: const Color(0xffc69b43),
                          ),
                        ),

                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),

                      const Expanded(
                        child: Column(
                          children: [

                            Text(
                              'Tasbeeh Counter',
                              style: TextStyle(
                                fontSize: 23,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                              ),
                            ),

                            SizedBox(height: 5),

                            

                          ],
                        ),
                      ),

                     
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                
                const SizedBox(height: 20),

                // Tasbeeh Dropdown
                Container(
                  width: screenWidth * 0.78,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 3,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(40),

                    border: Border.all(
                      color: const Color(0xffd9ad51),
                      width: 2,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: DropdownButtonHideUnderline(

                    child: DropdownButton<String>(

                      value: selectedTasbeeh,
                      isExpanded: true,
                      dropdownColor: const Color(0xff075b50),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 30,
                      ),

                      items: tasbeehList.map((tasbeeh) {

                        return DropdownMenuItem<String>(
                          value: tasbeeh['name'],

                          child: Row(
                            children: [

                              Icon(
  FlutterIslamicIcons.solidTasbih3, 
  size: 32,
  color: const Color.fromARGB(255, 235, 228, 225),
),

                              const SizedBox(width: 12),

                              Text(
                                tasbeeh['name']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                            ],
                          ),
                        );

                      }).toList(),

                      onChanged: (value) {

                        setState(() {
                          selectedTasbeeh = value!;
                          count = 0;
                        });

                      },
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Daily Streak
                Container(
                  width: 210,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 18,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xff004d43),
                    borderRadius: BorderRadius.circular(35),

                    border: Border.all(
                      color: const Color(0xffffce62),
                      width: 1.5,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffffc44e).withOpacity(0.2),
                        blurRadius: 15,
                      ),
                    ],
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 35,
                      ),

                      const SizedBox(width: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text(
                            'Daily Streak',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),

                          Text(
                            '$streak Days',
                            style: const TextStyle(
                              color: Color(0xffffd36c),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                        ],
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // Main Counter
                GestureDetector(

                  onTap: () {

                    setState(() {
                      count++;
                    });

                  },

                  child: Container(

                    height: counterSize,
                    width: counterSize,

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      gradient: const LinearGradient(
                        colors: [
                          Color(0xffffdf82),
                          Color(0xffb87924),
                          Color(0xffffd36c),
                          Color(0xff93601c),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xffffca5c).withOpacity(0.35),
                          blurRadius: 25,
                          spreadRadius: 4,
                        ),
                      ],
                    ),

                    child: Container(

                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: const Color(0xff064c43),

                        border: Border.all(
                          color: const Color(0xfffce4a2),
                          width: 3,
                        ),
                      ),

                      child: Container(

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,

                          gradient: const RadialGradient(
                            colors: [
                              Color(0xfffff9e8),
                              Color(0xfff3e6c5),
                              Color(0xfffff7e4),
                            ],
                          ),

                          border: Border.all(
                            color: const Color(0xffc99539),
                            width: 3,
                          ),
                        ),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [

                            Icon(
  FlutterIslamicIcons.solidMosque, 
  size: 72,
  color: Color(0xff003d35),
),

 
                            // Counter Number
                            FittedBox(
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  fontSize: 95,
                                  color: Color(0xff003d35),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

 
                            Container(
                              height: 2,
                              width: 100,
                              color: const Color(0xffb58b35),
                            ),

 
                            const Text(
                              'TAP TO COUNT',
                              style: TextStyle(
                                color: Color(0xff00685b),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),

                           SizedBox(height: 5),

                             
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Reset Button
                Container(
                  width: 185,
                  height: 58,

                  decoration: BoxDecoration(
                    color: const Color(0xff00685c),
                    borderRadius: BorderRadius.circular(40),

                    border: Border.all(
                      color: const Color(0xffffd16a),
                      width: 2,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: TextButton.icon(

                    onPressed: () {

                      showDialog(
                        context: context,

                        builder: (context) {

                          return AlertDialog(

                            backgroundColor: const Color(0xff075448),

                            title: const Text(
                              'Reset Counter?',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),

                            content: const Text(
                              'Do you want to reset your current Tasbeeh count?',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),

                            actions: [

                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),

                              TextButton(
                                onPressed: () {

                                  setState(() {
                                    count = 0;
                                  });

                                  Navigator.pop(context);

                                },
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(
                                    color: Color(0xffffd36c),
                                  ),
                                ),
                              ),

                            ],
                          );

                        },
                      );

                    },

                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 25,
                    ),

                    label: const Text(
                      'Reset',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                 
                const SizedBox(height: 25),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

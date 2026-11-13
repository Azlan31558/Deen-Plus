import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:islamicapp/99naames.dart';
import 'package:islamicapp/SavedSurahsScreen.dart';
import 'package:islamicapp/ahadees.dart';
import 'package:islamicapp/dailyazkar.dart';
import 'package:islamicapp/islamicai.dart';
import 'package:islamicapp/juzzlist.dart';
import 'package:islamicapp/mp3quran.dart';
import 'package:islamicapp/prayer.dart';
import 'package:islamicapp/surahlist.dart';
import 'package:islamicapp/tasbeh.dart';

class AllahNames extends StatefulWidget {
  const AllahNames({super.key});

  @override
  State<AllahNames> createState() => _AllahNamesState();
}

class _AllahNamesState extends State<AllahNames> {

  List categ = [];
  List categB = [];
  Map<String, String> prayerTimes = {};
  String currentPrayer = 'Fajr';
  String nextPrayer = 'Dhuhr';
  String nextPrayerTime = '---';
  String remainingTimeText = 'Loading...';
  Timer? _timer;

  final List<String> _prayerOrder = const [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  int _parsePrayerMinutes(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 0;

    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
    if (match == null) return 0;

    final hour = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;

    return (hour * 60) + minute;
  }

  String _formatTimeFromMinutes(int minutes) {
    final total = minutes % (24 * 60);
    final hour = total ~/ 60;
    final minute = total % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatRemaining(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours <= 0 && minutes <= 0) {
      return 'Now';
    }

    return '${hours}h ${minutes}m';
  }

  void _updatePrayerBanner() {
    if (prayerTimes.isEmpty) {
      currentPrayer = 'Fajr';
      nextPrayer = 'Dhuhr';
      nextPrayerTime = '---';
      remainingTimeText = 'Loading...';
      return;
    }

    final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
    final prayerMinutes = <String, int>{
      for (final prayer in _prayerOrder)
        prayer: _parsePrayerMinutes(prayerTimes[prayer]),
    };

    int currentIndex = -1;

    for (int i = 0; i < _prayerOrder.length; i++) {
      if (prayerMinutes[_prayerOrder[i]]! <= nowMinutes) {
        currentIndex = i;
      }
    }

    if (currentIndex == -1) {
      currentPrayer = 'Isha';
      nextPrayer = 'Fajr';
      nextPrayerTime = _formatTimeFromMinutes(prayerMinutes['Fajr']!);
      remainingTimeText = _formatRemaining(
        (prayerMinutes['Fajr']! + (24 * 60)) - nowMinutes,
      );
      return;
    }

    currentPrayer = _prayerOrder[currentIndex];

    if (currentIndex < _prayerOrder.length - 1) {
      nextPrayer = _prayerOrder[currentIndex + 1];
      nextPrayerTime = _formatTimeFromMinutes(prayerMinutes[nextPrayer]!);
      remainingTimeText = _formatRemaining(
        prayerMinutes[nextPrayer]! - nowMinutes,
      );
    } else {
      nextPrayer = 'Fajr';
      nextPrayerTime = _formatTimeFromMinutes(prayerMinutes['Fajr']! + (24 * 60));
      remainingTimeText = _formatRemaining(
        (prayerMinutes['Fajr']! + (24 * 60)) - nowMinutes,
      );
    }
  }

  Future<void> _fetchPrayerTimings() async {
    try {
      final now = DateTime.now();
      final date =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

      final response = await http.get(
        Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity/$date?city=Sahiwal&country=Pakistan&method=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timings = data['data']['timings'];

        final parsedTimes = {
          'Fajr': timings['Fajr']?.toString() ?? '',
          'Dhuhr': timings['Dhuhr']?.toString() ?? '',
          'Asr': timings['Asr']?.toString() ?? '',
          'Maghrib': timings['Maghrib']?.toString() ?? '',
          'Isha': timings['Isha']?.toString() ?? '',
        };

        if (!mounted) return;

        setState(() {
          prayerTimes = parsedTimes;
          _updatePrayerBanner();
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        prayerTimes = {
          'Fajr': '04:30',
          'Dhuhr': '12:38',
          'Asr': '15:49',
          'Maghrib': '18:58',
          'Isha': '20:26',
        };
        _updatePrayerBanner();
      });
    }
  }

  String _displayPrayerTime(String prayerName) {
    final raw = prayerTimes[prayerName] ?? '';
    if (raw.isEmpty) return '--';

    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) return raw;

    final hour = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _normalizeScreenName(dynamic value) {
    final text = value?.toString() ?? '';
    return text
        .trim()
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  Future getcategory() async {
    var res = await http.post(Uri.parse('https://devtechnical.com/AllUser/categqur.php'),
    
    );
    var result = jsonDecode(res.body);
    setState(() {
      categ = result;
    });
    
  }

  Future getcategoryB() async {
    var res = await http.post(Uri.parse('https://devtechnical.com/AllUser/getquranB.php'),
    
    );
    var result = jsonDecode(res.body);
    setState(() {
      categB = result;
    });
  }
  
   @override
  void initState() {
     getcategory();
     getcategoryB();
     _fetchPrayerTimings();
     _timer = Timer.periodic(const Duration(seconds: 30), (_) {
       if (mounted) {
         setState(() {
           _updatePrayerBanner();
         });
       }
     });

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xfffe8f2f2),      
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 232, 236, 236),
         toolbarHeight: 80,
         title: Text('Deen Plus',style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold)),
        actions: [
             Padding(
               padding: const EdgeInsets.only(right: 22.0),
               child: Container(
                    height: 45,
                    width: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Color(0xfffe8f5f4),
                      border: Border.all(color:  Color.fromARGB(255, 160, 192, 189),)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        Icon(Icons.location_pin,color: Color.fromARGB(255, 5, 63, 61),),
                        Text('Sahiwal',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w600,color: Color(0xfff7e8a93)),),
                      ],
                    ),
                  ),
             ),
        ],         
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 22.0,right: 22),
          child: Column(
            spacing: 5,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               SizedBox(height: 3,),
               Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('Assalam o Alaikum,',style: TextStyle(fontSize: 17,color: Colors.blueGrey),),
                  ],
               ),
               Stack(
                 children: [
                  Container(
                                height: 145,
                                width: MediaQuery.of(context).size.width,
                                decoration:  BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.blueGrey),
                  color: Colors.lightBlue
                                 ),
                               ),
                ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(22),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(const Color.fromARGB(255, 5, 63, 61),BlendMode.colorBurn),
                    child: Image.network('https://tse3.mm.bing.net/th/id/OIP.w6J9yhQjRFdTUGRCWC_XfAHaE7?r=0&pid=Api&h=220&P=0',height: 145,width: MediaQuery.of(context).size.width,fit: BoxFit.cover,))),
                    Container(
                                height: 145,
                                width: MediaQuery.of(context).size.width,
                                decoration:  BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.blueGrey),
                  gradient: LinearGradient(colors: [
                    Color.fromARGB(255, 7, 104, 101),
                    Color.fromARGB(235, 7, 104, 101),
                    Color.fromARGB(183, 19, 129, 126),
                  ])
                                 ),
                               ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(                    
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('CURRENT PRAYER',style: TextStyle(fontSize: 13,color: const Color.fromARGB(255, 219, 216, 216),fontWeight: FontWeight.bold),),
                              Text('AZAN TIME',style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold,color: const Color.fromARGB(255, 219, 216, 216)),),
                            ],
                          ),
                          SizedBox(height: 5,),
                          Row(                    
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(currentPrayer,style: TextStyle(fontSize: 25,fontWeight: FontWeight.w900,color: Colors.white),),
Text(
  '${_displayPrayerTime(currentPrayer)} - $nextPrayerTime',
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  ),
),                            ],
                          ),
                            SizedBox(height: 10,),
                           Divider(height: 4,),
                            SizedBox(height: 10,),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                               Expanded(
                                child: Text(
                                  'Next Prayer: $nextPrayer at $nextPrayerTime',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color.fromARGB(255, 223, 219, 219),
                                  ),
                                ),
                              ),
                              Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Remaining: $remainingTimeText',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color.fromARGB(255, 255, 245, 180),
                              ),
                            ),
                          ),
                            ],
                          ),
                          SizedBox(height: 4,),
                          
                        ],
                      ),
                    ),
                ],
               ),
               Container(
                height: 55,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: const Color(0xfffffffff),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 19.0,right: 19),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          Icon(Icons.search_off_outlined,color: Color(0xFff118785) ,),
                          Text('Ask anything....',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.teal ),),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            height: 40,
                            width: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color:   Colors.teal ,
                              border: Border.all(color: const Color.fromARGB(255, 166, 186, 196),)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 10,
                              children: [                         
                                Text('Islamic',style: TextStyle(fontSize: 16,color: const Color.fromARGB(255, 226, 222, 222)),),
                                Text('AI',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w600,color: Colors.white),),
                              ],
                            ),
                          ),
                          Icon(Icons.mic,size: 37,color:   Colors.teal ),
                        ],
                      ),
                    ],
                  ),
                ),
               ),
               SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categ.length,
                  itemBuilder: (context, index) {
                    final item = categ[index] as Map<String, dynamic>;
                    final name = (item['name'] ?? '').toString().trim().toLowerCase();

                    return Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(21),
                        onTap: () {
                          if (name.contains('surah')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Surahlist(),
                              ),
                            );
                          } else if (name.contains('juzz') || name.contains('juz')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Paralist(),
                              ),
                            );
                          } else if (name.contains('mp3')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Mp3PlayerScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SavedScreen(),
                              ),
                            );
                          }                    
                        },
                        child: Container(
                          height: 80,
                          width: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: const Color(0xffffffff),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 45,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: const Color(0xfffecf5f4),
                                  ),
                                  child: const Icon(Icons.article),
                                ),
                                Text(
                                  (item['name'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  (item['subname'] ?? '').toString(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
               ),
        
               Row(
                spacing: 6,
                children: [
                  Container(
                    height: 45,
                    width: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.teal,
                    ),
                  ),
                  Text('More Features',style: TextStyle(fontSize: 19,fontWeight: FontWeight.w800,color: Color.fromARGB(255, 100, 107, 116)),),              
                ],
               ),
        
              GridView.count(
  shrinkWrap: true,
  childAspectRatio: 1.3,
  mainAxisSpacing: 10,
  crossAxisSpacing: 10,
  physics: NeverScrollableScrollPhysics(),
  crossAxisCount: 3,

  children: List.generate(categB.length, (index) {

    return InkWell(
      borderRadius: BorderRadius.circular(22),

      onTap: () {

        final screenName = _normalizeScreenName(categB[index]['timing']);

        switch (screenName) {

          case 'prayer timing':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const prayertime(),
              ),
            );
            break;

          case 'islamic ai':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IslamicAiScreen(),
              ),
            );
            break;

          case 'ahadees':
          case 'hadith':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AhadeesScreen(),
              ),
            );
            break;

          case 'daily azkar':
          case 'dailyazkar':
          case 'azkar':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DailyAzkarScreen(),
              ),
            );
            break;

          case 'tasbeeh':
          case 'tasbeh':
          case 'tasbeeh counter':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TasbeehScreen(),
              ),
            );
            break;

          case '99 names':
          case 'allah names':
          case 'asma ul husna':
          case 'asmaulhusna':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Names99Screen(),
              ),
            );
            break;

          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Screen not found: ${categB[index]['timing']}'),
              ),
            );
        }
      },

      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color(0xffffffff),
        ),

        child: Padding(
          padding: const EdgeInsets.all(8.0),

          child: Column(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [

              Container(
                height: 40,
                width: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xffecf5f4),
                ),

                child: const Icon(
                  Icons.mosque,
                  color: Color(0xff118785),
                  size: 25,
                ),
              ),

              Text(
                categB[index]['timing'].toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }),
)               
            ],
          ),
        ),
      ),
    );
  }
}
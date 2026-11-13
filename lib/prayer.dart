
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class prayertime extends StatefulWidget {
  const prayertime({super.key});

  @override
  State<prayertime> createState() => _prayertimeState();
}

class _prayertimeState extends State<prayertime> {
  bool select = false;

  List<Map<String, dynamic>> names = [];

  bool isLoading = true;
  String errorMessage = '';
  String readableDate = '';
  String hijriDate = '';

  // API Function
  Future getprayertime() async {
    try {
      // Get today's date dynamically
      DateTime now = DateTime.now();

      String date =
          "${now.day.toString().padLeft(2, '0')}-"
          "${now.month.toString().padLeft(2, '0')}-"
          "${now.year}";

      var res = await http.get(
        Uri.parse(
          "https://api.aladhan.com/v1/timingsByCity/$date"
          "?city=Sahiwal&country=Pakistan&method=1",
        ),
      );

      if (res.statusCode == 200) {
        var result = jsonDecode(res.body);

        var timings = result['data']['timings'];
        var dateData = result['data']['date'];

        setState(() {
          // Actual API data
          names = [
            {
              "name": "Fajr",
              "time": timings['Fajr'],
              "description": "Dawn",
              "icon": Icons.nightlight_round,
            },
            {
              "name": "Dhuhr",
              "time": timings['Dhuhr'],
              "description": "Midday",
              "icon": Icons.wb_sunny,
            },
            {
              "name": "Asr",
              "time": timings['Asr'],
              "description": "Afternoon",
              "icon": Icons.wb_cloudy,
            },
            {
              "name": "Maghrib",
              "time": timings['Maghrib'],
              "description": "Sunset",
              "icon": Icons.sunny,
            },
            {
              "name": "Isha",
              "time": timings['Isha'],
              "description": "Night",
              "icon": Icons.nightlight_round,
            },
          ];

          // Date from API
          readableDate = dateData['readable'];
          hijriDate = dateData['hijri']['date'];

          isLoading = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load prayer timings";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    getprayertime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Prayer Time",
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xff149A98),
        foregroundColor: Colors.white,
      ),

      backgroundColor: Color(0xFFFBF7EE),

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),

          child: Column(
            children: [

              // Top Prayer Card
              Stack(
                children: [
                  Container(
                    height: 145,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.blueGrey),
                      color: Colors.lightBlue,
                    ),
                  ),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),

                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        const Color.fromARGB(255, 5, 63, 61),
                        BlendMode.colorBurn,
                      ),

                      child: Image.network(
                        'https://tse3.mm.bing.net/th/id/OIP.w6J9yhQjRFdTUGRCWC_XfAHaE7?r=0&pid=Api&h=220&P=0',
                        height: 145,
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  Container(
                    height: 145,
                    width: MediaQuery.of(context).size.width,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.blueGrey),

                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 7, 104, 101),
                          Color.fromARGB(235, 7, 104, 101),
                          Color.fromARGB(183, 19, 129, 126),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),

                    child: Column(
                      children: [

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children: [
                            Text(
                              'PRAYER SCHEDULE',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              'TODAY',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 5),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children: [
                            Text(
                              isLoading ? 'Loading...' : 'Sahiwal',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),

                            Text(
                              readableDate,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8),

                        Divider(height: 4),

                        SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: Color(0xffFFD86A),
                              size: 17,
                            ),

                            SizedBox(width: 7),

                            Text(
                              hijriDate.isEmpty
                                  ? 'Hijri Date'
                                  : 'Hijri: $hijriDate',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 15),

              // Prayers + Notification Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Text(
                    "Prayers",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Row(
                    children: [
                      Text("Enable Notifications"),

                      SizedBox(width: 6),

                      GestureDetector(
                        onTap: () {
                          setState(() {
                            select = !select;
                          });
                        },

                        child: Icon(
                          select == false
                              ? Icons.toggle_off
                              : Icons.toggle_on,
                          color: Colors.green,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Loading
              if (isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff149A98),
                  ),
                )

              // Error
              else if (errorMessage.isNotEmpty)
                Column(
                  children: [
                    Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),

                    SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                          errorMessage = '';
                        });

                        getprayertime();
                      },

                      child: Text("Retry"),
                    ),
                  ],
                )

              // API Data ListView
              else
                ListView.builder(
                  itemCount: names.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),

                  itemBuilder: (context, index) {

                    return Container(
                      padding: EdgeInsets.all(12),

                      margin: EdgeInsets.only(bottom: 10),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),

                      child: Row(
                        children: [

                          // Prayer Icon
                          Container(
                            padding: EdgeInsets.all(10),

                            decoration: BoxDecoration(
                              color: Color(0xFFFFF0C4),
                              borderRadius: BorderRadius.circular(8),
                            ),

                            child: Icon(
                              names[index]['icon'],
                            ),
                          ),

                          SizedBox(width: 12),

                          // Prayer Name and Description
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              Text(
                                names[index]['name'],

                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                names[index]['description'],
                              ),
                            ],
                          ),

                          Spacer(),

                          // Actual API Prayer Time
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,

                            children: [
                              Text(
                                "Azan",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                names[index]['time'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff149A98),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(width: 8),

                          // Notification Icon
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                select = !select;
                              });
                            },

                            child: Icon(
                              select == true
                                  ? Icons.notifications
                                  : Icons.notifications_outlined,

                              color: Colors.green,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

            ],
          ),
        ),
      ),
    );
  }
}

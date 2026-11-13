import 'package:flutter/material.dart';
// import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:intl/intl.dart';

class IslamicCalendarPage extends StatefulWidget {
  const IslamicCalendarPage({super.key});

  @override
  State<IslamicCalendarPage> createState() => _IslamicCalendarPageState();
}

class _IslamicCalendarPageState extends State<IslamicCalendarPage> {
  final Color teal = const Color(0xff149A98);
  final Color background = const Color(0xffF5FAFA);

  late DateTime selectedDate;
  late HijriCalendarConfig selectedHijri;

  int hijriYear = 1448;
  int hijriMonth = 2;

  @override
  void initState() {
    super.initState();

    selectedDate = DateTime.now();

    selectedHijri = HijriCalendarConfig.fromGregorian(selectedDate);

    hijriYear = selectedHijri.hYear;
    hijriMonth = selectedHijri.hMonth;
  }

  String get hijriMonthName {
    return monthNames[hijriMonth] ?? '';
  }

  int get daysInHijriMonth {
    if (hijriMonth % 2 == 1) {
      return 30;
    }

    if (hijriMonth == 12) {
      return 30;
    }

    return 29;
  }

  DateTime hijriToGregorian(int day) {
    final hijri = HijriCalendarConfig.fromHijri(hijriYear, hijriMonth, day);

    return hijri.hijriToGregorian(hijriYear, hijriMonth, day);
  }

  void nextMonth() {
    setState(() {
      hijriMonth++;

      if (hijriMonth > 12) {
        hijriMonth = 1;
        hijriYear++;
      }
    });
  }

  void previousMonth() {
    setState(() {
      hijriMonth--;

      if (hijriMonth < 1) {
        hijriMonth = 12;
        hijriYear--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- HEADER ----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Calendar",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff18263B),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        height: 6,
                        width: 62,
                        decoration: BoxDecoration(
                          color: teal,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),

                  // Location
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xffEFF8F7),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: const Color(0xffD6E9E8)),
                    ),

                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: teal, size: 27),

                        const SizedBox(width: 8),

                        const Text(
                          "City not found",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff25334A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ---------------- TODAY CARD ----------------
              Container(
                width: double.infinity,
                height: 80,
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    Container(
                      height: 60,
                      width: 60,

                      decoration: BoxDecoration(
                        color: const Color(0xffEAF7F6),
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Icon(Icons.calendar_month, color: teal, size: 25),
                    ),

                    const SizedBox(width: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Date",
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xff66758A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          DateFormat(
                            'EEEE, dd MMMM yyyy',
                          ).format(DateTime.now()),

                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff202C3F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ---------------- HIJRI HEADER ----------------
              Container(
                width: double.infinity,
                height: 70,
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 16,
                ),

                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xff118C8B), const Color(0xff20A6A4)],
                  ),

                  borderRadius: BorderRadius.circular(32),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous
                    _arrowButton(Icons.chevron_left, previousMonth),

                    Column(
                      children: [
                        Text(
                          "$hijriMonthName $hijriYear AH",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 1),

                        Text(
                          _gregorianMonthText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Next
                    _arrowButton(Icons.chevron_right, nextMonth),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ---------------- WEEK DAYS ----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _WeekDay("Sun"),
                  _WeekDay("Mon"),
                  _WeekDay("Tue"),
                  _WeekDay("Wed"),
                  _WeekDay("Thu"),
                  _WeekDay("Fri"),
                  _WeekDay("Sat"),
                ],
              ),

              const SizedBox(height: 10),

              // ---------------- CALENDAR GRID ----------------
              _buildCalendarGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _arrowButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(18),

      child: Container(
        height: 40,
        width: 40,

        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),

        child: Icon(icon, color: Colors.white, size: 38),
      ),
    );
  }

  String _gregorianMonthText() {
    try {
      final date = hijriToGregorian(1);

      return DateFormat(' MMM / yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  Widget _buildCalendarGrid() {
    final firstDate = hijriToGregorian(1);

    int startingWeekday = firstDate.weekday % 7;

    List<Widget> days = [];

    // Empty spaces before first day
    for (int i = 0; i < startingWeekday; i++) {
      days.add(const SizedBox());
    }

    // Days
    for (int day = 1; day <= daysInHijriMonth; day++) {
      final gregorianDate = hijriToGregorian(day);

      final bool isSelected =
          gregorianDate.year == selectedDate.year &&
          gregorianDate.month == selectedDate.month &&
          gregorianDate.day == selectedDate.day;

      final bool isToday =
          gregorianDate.year == DateTime.now().year &&
          gregorianDate.month == DateTime.now().month &&
          gregorianDate.day == DateTime.now().day;

      days.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedDate = gregorianDate;
            });
          },

          child: Container(
            margin: const EdgeInsets.all(4),

            height: 67,

            decoration: BoxDecoration(
              color: isSelected ? teal : Colors.transparent,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(
                color: isSelected || isToday ? teal : const Color(0xffE7EEEE),
              ),
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Text(
                  day.toString(),

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,

                    color: isSelected ? Colors.white : const Color(0xff26354A),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  gregorianDate.day.toString(),

                  style: TextStyle(
                    fontSize: 10,

                    color: isSelected
                        ? Colors.white70
                        : const Color(0xff8A97A8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,

      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      childAspectRatio: 0.75,

      children: days,
    );
  }
}

class _WeekDay extends StatelessWidget {
  final String text;

  const _WeekDay(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xff66758A),
      ),
    );
  }
}

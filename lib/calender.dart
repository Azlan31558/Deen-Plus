import 'package:flutter/material.dart';
import 'package:islamic_hijri_calendar/islamic_hijri_calendar.dart';

class Calender extends StatefulWidget {
  const Calender({super.key});

  @override
  State<Calender> createState() => _CalenderState();
}

class _CalenderState extends State<Calender> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2F2),
      appBar: AppBar(
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFFE3E6E7),
            width: 2.0,
          ),
        ),
        backgroundColor: const Color(0xFFE8F2F2),
        toolbarHeight: 90,
        title: const Text(
          'Calendar',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 22.0),
            child: Container(
              height: 45,
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color(0xFFE8F5F4),
                border: Border.all(color: const Color(0xFFA0C0BD)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  Icon(
                    Icons.location_pin,
                    color: Color(0xFF053F3D),
                  ),
                  Text(
                    'Sahiwal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7E8A93),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          IslamicHijriCalendar(
            isHijriView: true,
            highlightBorder: colorScheme.primary,
            highlightTextColor: colorScheme.surface,
            defaultTextColor: colorScheme.onSurface,
            defaultBackColor: colorScheme.surface,
            adjustmentValue: 0,
            isGoogleFont: true,
            fontFamilyName: 'Lato',
            getSelectedEnglishDate: (selectedDate) {
              debugPrint('English Date : $selectedDate');
            },
            getSelectedHijriDate: (selectedDate) {
              debugPrint('Hijri Date : $selectedDate');
            },
            isDisablePreviousNextMonthDates: true,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:islamicapp/SavedSurahsScreen.dart';

class AyahScreen extends StatelessWidget {
  final Map<String, dynamic> surah;
  final int ayahNumber;

  const AyahScreen({super.key, required this.surah, required this.ayahNumber});

  // Temporary Ayah data
  // Later we can replace this with Quran API data.
  String getAyahText() {
    if (surah['number'] == 1) {
      switch (ayahNumber) {
        case 1:
          return 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

        case 2:
          return 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ';

        case 3:
          return 'الرَّحْمَٰنِ الرَّحِيمِ';

        case 4:
          return 'مَالِكِ يَوْمِ الدِّينِ';

        case 5:
          return 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ';

        case 6:
          return 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ';

        case 7:
          return 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ';

        default:
          return 'Ayah not available';
      }
    }

    return 'Ayah $ayahNumber of ${surah['name']}';
  }

  String getTranslation() {
    if (surah['number'] == 1) {
      switch (ayahNumber) {
        case 1:
          return 'In the name of Allah, the Most Compassionate, Most Merciful.';

        case 2:
          return 'All praise is for Allah—Lord of the worlds.';

        case 3:
          return 'The Most Compassionate, Most Merciful.';

        case 4:
          return 'Master of the Day of Judgment.';

        case 5:
          return 'You alone we worship and You alone we ask for help.';

        case 6:
          return 'Guide us along the Straight Path.';

        case 7:
          return 'The Path of those You have blessed—not those You are displeased with, or those who are astray.';

        default:
          return 'Translation not available';
      }
    }

    return 'Translation for this Ayah is not available yet.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f8f7),

      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,

        title: Text(
          '${surah['name']} - Ayah $ayahNumber',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ayah Number
            Align(
              alignment: Alignment.center,
              child: Container(
                height: 55,
                width: 55,

                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Center(
                  child: Text(
                    ayahNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Arabic Ayah
            Container(
              padding: const EdgeInsets.all(25),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),

              child: Text(
                getAyahText(),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 30,
                  height: 2,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Translation
            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Translation',
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    getTranslation(),
                    style: const TextStyle(fontSize: 18, height: 1.6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await SavedStorage.saveItem({
                        'id': 'ayah-${surah['number']}:$ayahNumber',
                        'category': 'Ayah',
                        'arabic': getAyahText(),
                        'translation': getTranslation(),
                        'reference': '${surah['name']} • Ayah $ayahNumber',
                      });
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bookmark added')),
                      );
                    },

                    icon: const Icon(Icons.bookmark_border),

                    label: const Text('Bookmark'),

                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,

                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

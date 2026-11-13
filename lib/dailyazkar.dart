import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:islamicapp/SavedSurahsScreen.dart';

const _dailyAzkarApiUrl =
    'https://raw.githubusercontent.com/MuhammadAhsan-Shafiq/99-Names-of-Allah-JSON/main/daily_azkar.json';

class DailyAzkarScreen extends StatefulWidget {
  const DailyAzkarScreen({super.key});

  @override
  State<DailyAzkarScreen> createState() => _DailyAzkarScreenState();
}

class _DailyAzkarScreenState extends State<DailyAzkarScreen> {
  final Color primary = const Color(0xff009688);
  final Color background = const Color(0xffEAF4F3);

  int selectedCategory = 0;
  bool _isLoading = true;
  String? _loadError;
  final TextEditingController searchController = TextEditingController();

  final List<String> categories = [
    'All Azkar',
    'Morning',
    'Evening',
    'After Prayer',
    'Sleep',
  ];

  List<Map<String, dynamic>> azkar = [];

  List<Map<String, dynamic>> get filteredAzkar {
    final query = searchController.text.trim().toLowerCase();

    return azkar.where((item) {
      final categoryMatch =
          selectedCategory == 0 ||
          (item['category']?.toString() ?? '') == categories[selectedCategory];
      final searchMatch =
          query.isEmpty ||
          (item['arabic']?.toString() ?? '').toLowerCase().contains(query) ||
          (item['translation']?.toString() ?? '').toLowerCase().contains(
            query,
          ) ||
          (item['reference']?.toString() ?? '').toLowerCase().contains(query);
      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAzkar();
  }

  Future<void> _loadAzkar() async {
    try {
      final response = await http
          .get(Uri.parse(_dailyAzkarApiUrl))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('API returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final parsed = _parseAzkarList(decoded);

      if (parsed.isEmpty) {
        throw const FormatException('No azkar found in API response');
      }

      if (!mounted) return;

      setState(() {
        azkar = parsed;
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        azkar = _fallbackAzkar();
        _isLoading = false;
        _loadError = null;
      });
    }
  }

  List<Map<String, dynamic>> _parseAzkarList(dynamic data) {
    final result = <Map<String, dynamic>>[];
    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          final map = item.map((key, value) => MapEntry(key.toString(), value));
          final category = (map['category'] ?? map['type'] ?? 'Morning')
              .toString();
          final arabic = (map['arabic'] ?? map['text'] ?? '').toString();
          final translation = (map['translation'] ?? map['meaning'] ?? '')
              .toString();
          if (arabic.trim().isNotEmpty) {
            result.add({
              'category': category,
              'arabic': arabic,
              'translation': translation,
              'reference': (map['reference'] ?? 'Daily Azkar').toString(),
            });
          }
        }
      }
    } else if (data is Map) {
      final items = data['azkar'] ?? data['items'] ?? data['data'];
      if (items is List) {
        return _parseAzkarList(items);
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _fallbackAzkar() {
    return [
      {
        'category': 'Morning',
        'arabic': 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ',
        'translation': 'ہم نے صبح کی اور تمام بادشاہی اللہ ہی کے لیے ہے۔',
        'reference': 'Sahih Muslim',
      },
      {
        'category': 'Morning',
        'arabic': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
        'translation': 'اللہ پاک ہے اور تمام تعریفیں اسی کے لیے ہیں۔',
        'reference': 'Sahih Muslim',
      },
      {
        'category': 'Evening',
        'arabic':
            'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
        'translation':
            'میں اللہ کے کامل کلمات کے ذریعے اس کی مخلوق کے شر سے پناہ مانگتا ہوں۔',
        'reference': 'Sahih Muslim',
      },
      {
        'category': 'After Prayer',
        'arabic': 'أَسْتَغْفِرُ اللَّهَ',
        'translation': 'میں اللہ سے مغفرت طلب کرتا ہوں۔',
        'reference': 'Sahih Muslim',
      },
      {
        'category': 'Sleep',
        'arabic': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
        'translation': 'اے اللہ! تیرے نام کے ساتھ میں مرتا اور زندہ ہوتا ہوں۔',
        'reference': 'Sahih al-Bukhari',
      },
    ];
  }

  Future<void> _bookmarkAzkar({
    required String category,
    required String arabic,
    required String translation,
    required String reference,
  }) async {
    await SavedStorage.saveItem({
      'id': 'azkar-${category.toLowerCase()}:$arabic',
      'category': 'Azkar',
      'arabic': arabic,
      'translation': translation,
      'reference': '$category • $reference',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bookmark added')));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F9F8),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff0A8C82), Color(0xff0B6A65)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Daily Azkar',
                                style: TextStyle(
                                  color: Color(0xff0B6A65),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'أذكار الصباح والمساء',
                                style: TextStyle(
                                  color: Color(0xff0F7A73),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xffCFE8E6)),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: _loadAzkar,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xff0B6A65),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Container(
                  //   margin: const EdgeInsets.symmetric(horizontal: 20),
                  //   padding: const EdgeInsets.all(18),
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(24),
                  //     gradient: const LinearGradient(
                  //       colors: [Color(0xff0D8A84), Color(0xff0A6B69)],
                  //     ),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: const Color(0xff0D8A84).withOpacity(0.25),
                  //         blurRadius: 12,
                  //         offset: const Offset(0, 7),
                  //       ),
                  //     ],
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       const CircleAvatar(
                  //         radius: 24,
                  //         backgroundColor: Colors.white24,
                  //         child: Icon(
                  //           Icons.auto_awesome,
                  //           color: Colors.white,
                  //           size: 24,
                  //         ),
                  //       ),
                  //       const SizedBox(width: 14),
                  //       Expanded(
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             const Text(
                  //               'Daily Reminder',
                  //               style: TextStyle(
                  //                 color: Colors.white,
                  //                 fontSize: 15,
                  //                 fontWeight: FontWeight.w700,
                  //               ),
                  //             ),
                  //             const SizedBox(height: 4),
                  //             Text(
                  //               '${azkar.length} beautiful supplications',
                  //               style: const TextStyle(
                  //                 color: Colors.white70,
                  //                 fontSize: 12,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //       const Icon(
                  //         Icons.arrow_forward_ios_rounded,
                  //         color: Colors.white,
                  //         size: 18,
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 46,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final selected = selectedCategory == index;
                        return GestureDetector(
                          onTap: () => setState(() => selectedCategory = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xff0B6A65)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xff0B6A65)
                                    : const Color(0xffD7EBE7),
                              ),
                              boxShadow: [
                                if (selected)
                                  BoxShadow(
                                    color: const Color(
                                      0xff0B6A65,
                                    ).withOpacity(0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              categories[index],
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xff0B6A65),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xffD5EAE8)),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Color(0xff0B6A65)),
                        hintText: 'Search Azkar...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: filteredAzkar.isEmpty
                        ? const Center(
                            child: Text(
                              'No Azkar Found',
                              style: TextStyle(
                                color: Color(0xff0B6A65),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: filteredAzkar.length,
                            itemBuilder: (context, index) {
                              final item = filteredAzkar[index];
                              final category =
                                  item['category']?.toString() ?? 'Daily';
                              final arabic = item['arabic']?.toString() ?? '';
                              final translation =
                                  item['translation']?.toString() ?? '';
                              final reference =
                                  item['reference']?.toString() ??
                                  'Daily Azkar';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 18),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xffD7EAE8),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xff0B8B82),
                                                Color(0xff0B6A65),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            category,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xffEAF7F6),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              reference,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end,
                                              style: const TextStyle(
                                                color: Color(0xff0B6A65),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Bookmark Azkar',
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _bookmarkAzkar(
                                            category: category,
                                            arabic: arabic,
                                            translation: translation,
                                            reference: reference,
                                          ),
                                          icon: const Icon(
                                            Icons.bookmark_border_rounded,
                                            color: Color(0xff0B6A65),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Center(
                                      child: Text(
                                        arabic,
                                        textAlign: TextAlign.center,
                                        textDirection: TextDirection.rtl,
                                        style: const TextStyle(
                                          color: Color(0xff0B6A65),
                                          fontSize: 28,
                                          height: 1.8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(
                                      thickness: 1,
                                      color: Color(0xffD9ECEA),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      translation,
                                      textAlign: TextAlign.right,
                                      textDirection: TextDirection.rtl,
                                      style: const TextStyle(
                                        color: Color(0xff1E2C2C),
                                        fontSize: 18,
                                        height: 1.8,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

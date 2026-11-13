import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:islamicapp/audio_player_service.dart';
import 'package:islamicapp/SavedSurahsScreen.dart';

class JuzDetailScreen extends StatefulWidget {
  final int juzNumber;

  const JuzDetailScreen({super.key, required this.juzNumber});

  @override
  State<JuzDetailScreen> createState() => _JuzDetailScreenState();
}

class _JuzDetailScreenState extends State<JuzDetailScreen> {
  List<Map<String, dynamic>> ayahs = [];
  List<List<Map<String, dynamic>>> pages = [];
  bool isLoading = true;
  final AudioPlayer audioPlayer = sharedAudioPlayer;
  late final PageController pageController;
  int currentPageIndex = 0;

  static const String _bismillahArabic =
      'بِسْمِ ٱللّٰهِ ٱلرَّحْمٰنِ ٱلرَّحِيمِ';

  int _getSurahNumber(Map<String, dynamic> ayah) {
    final dynamic surahValue = ayah['surah'];
    if (surahValue is Map) {
      final dynamic surahNumber = surahValue['number'];
      if (surahNumber is int) {
        return surahNumber;
      }
      if (surahNumber != null) {
        return int.tryParse(surahNumber.toString()) ?? 0;
      }
    }

    final dynamic rawNumber = ayah['surahNumber'];
    if (rawNumber is int) {
      return rawNumber;
    }
    if (rawNumber != null) {
      return int.tryParse(rawNumber.toString()) ?? 0;
    }

    return 0;
  }

  String _getSurahDisplayName(Map<String, dynamic> ayah) {
    final dynamic surahValue = ayah['surah'];
    if (surahValue is Map) {
      final value =
          surahValue['name'] ??
          surahValue['englishName'] ??
          surahValue['englishNameTranslation'] ??
          surahValue['english'];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    const fallbackMap = {
      1: 'الفاتحة',
      2: 'البقرة',
      3: 'آل عمران',
      4: 'النساء',
      5: 'المائدة',
      6: 'الأنعام',
      7: 'الأعراف',
      8: 'الأنفال',
      9: 'التوبة',
      10: 'يونس',
    };

    return fallbackMap[_getSurahNumber(ayah)] ?? 'سورة';
  }

  bool _shouldShowSurahHeader(int index) {
    if (index == 0) {
      return true;
    }

    return _getSurahNumber(ayahs[index]) != _getSurahNumber(ayahs[index - 1]);
  }

  List<List<Map<String, dynamic>>> _groupAyahsByPage(
    List<Map<String, dynamic>> loadedAyahs,
  ) {
    final groupedAyahs = <int, List<Map<String, dynamic>>>{};
    for (final ayah in loadedAyahs) {
      final page = ayah['page'] as int? ?? 0;
      groupedAyahs.putIfAbsent(page, () => []).add(ayah);
    }
    final pageNumbers = groupedAyahs.keys.toList()..sort();
    return pageNumbers.map((page) => groupedAyahs[page]!).toList();
  }

  Future<void> loadJuzAyahs() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.alquran.cloud/v1/juz/${widget.juzNumber}/quran-uthmani',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] as Map<String, dynamic>? ?? {};
        final List<dynamic> rawAyahs = data['ayahs'] as List<dynamic>? ?? [];

        final translatedResponse = await http.get(
          Uri.parse(
            'https://api.alquran.cloud/v1/juz/${widget.juzNumber}/ur.ahmedali',
          ),
        );

        final audioResponse = await http.get(
          Uri.parse(
            'https://api.alquran.cloud/v1/juz/${widget.juzNumber}/ar.alafasy',
          ),
        );

        final List<Map<String, dynamic>> parsedAyahs = rawAyahs
            .asMap()
            .entries
            .map<Map<String, dynamic>>((entry) {
              final item = entry.value as Map<String, dynamic>;
              final surahData = item['surah'] is Map
                  ? item['surah'] as Map
                  : <String, dynamic>{};
              final surahNumber = surahData['number'] is int
                  ? surahData['number'] as int
                  : int.tryParse('${surahData['number']}') ?? 0;
              final numberInSurah = item['numberInSurah'] is int
                  ? item['numberInSurah'] as int
                  : int.tryParse('${item['numberInSurah']}') ?? 0;

              return {
                'number': entry.key + 1,
                'text': item['text'] ?? '',
                'translation': '',
                'audio': '',
                'surah': surahData,
                'surahNumber': surahNumber,
                'numberInSurah': numberInSurah,
                'page': item['page'] is int ? item['page'] as int : 0,
              };
            })
            .toList();

        if (translatedResponse.statusCode == 200) {
          final translatedData = jsonDecode(translatedResponse.body);
          final translatedAyahs =
              translatedData['data']['ayahs'] as List<dynamic>? ?? [];

          for (
            int i = 0;
            i < parsedAyahs.length && i < translatedAyahs.length;
            i++
          ) {
            parsedAyahs[i]['translation'] =
                translatedAyahs[i]['text']?.toString() ??
                'ترجمہ دستیاب نہیں ہے';
          }
        }

        if (audioResponse.statusCode == 200) {
          final audioData = jsonDecode(audioResponse.body);
          final audioAyahs = audioData['data']['ayahs'] as List<dynamic>? ?? [];

          for (
            int i = 0;
            i < parsedAyahs.length && i < audioAyahs.length;
            i++
          ) {
            parsedAyahs[i]['audio'] = audioAyahs[i]['audio']?.toString() ?? '';
          }
        }

        if (!mounted) return;

        setState(() {
          ayahs = parsedAyahs;
          pages = _groupAyahsByPage(parsedAyahs);
          currentPageIndex = 0;
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Juz detail load error: $e');
    }

    if (!mounted) return;

    setState(() {
      ayahs = [];
      isLoading = false;
    });
  }

  void showAyahDialog(Map<String, dynamic> ayah) {
    final String arabicText = ayah['text']?.toString() ?? '';
    final String translation =
        ayah['translation']?.toString() ?? 'ترجمہ دستیاب نہیں ہے';
    final String audioUrl = ayah['audio']?.toString() ?? '';
    final String mediaItemId =
        'juz-${widget.juzNumber}:${ayah['surahNumber']}:${ayah['numberInSurah']}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: Color(0xfff9fbfb),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffe7f3f1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'آیت ${ayah['number']} ',
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              arabicText,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 28,
                                height: 2,
                                fontFamily: 'serif',
                                fontWeight: FontWeight.w600,
                                color: Color(0xff0f172a),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xffeefaf8),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                translation,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.9,
                                  color: Color(0xff1f2937),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              StreamBuilder<PlayerState>(
                                stream: audioPlayer.playerStateStream,
                                initialData: audioPlayer.playerState,
                                builder: (context, snapshot) {
                                  final playerState = snapshot.data;
                                  final currentTag = audioPlayer
                                      .sequenceState
                                      .currentSource
                                      ?.tag;
                                  final isCurrentAyah =
                                      currentTag is MediaItem &&
                                      currentTag.id == mediaItemId;
                                  final isAyahPlaying =
                                      playerState?.playing == true &&
                                      isCurrentAyah;

                                  return Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: audioUrl.isEmpty
                                          ? null
                                          : () async {
                                              if (isCurrentAyah) {
                                                if (isAyahPlaying) {
                                                  await audioPlayer.pause();
                                                } else {
                                                  if (playerState
                                                          ?.processingState ==
                                                      ProcessingState
                                                          .completed) {
                                                    await audioPlayer.seek(
                                                      Duration.zero,
                                                    );
                                                  }
                                                  await audioPlayer.play();
                                                }
                                                return;
                                              }

                                              await audioPlayer.stop();
                                              await audioPlayer.setAudioSource(
                                                AudioSource.uri(
                                                  Uri.parse(audioUrl),
                                                  tag: MediaItem(
                                                    id: mediaItemId,
                                                    album:
                                                        'Juz ${widget.juzNumber}',
                                                    title:
                                                        '${_getSurahDisplayName(ayah)} - Ayah ${ayah['numberInSurah']}',
                                                    artist: 'القرآن الكريم',
                                                  ),
                                                ),
                                              );
                                              await audioPlayer.play();
                                            },
                                      icon: Icon(
                                        isAyahPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                      ),
                                      label: Text(
                                        isAyahPlaying ? 'Pause' : 'Play',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await SavedStorage.saveItem({
                                      'id':
                                          'ayah-${ayah['surahNumber']}:${ayah['numberInSurah']}',
                                      'category': 'Ayah',
                                      'arabic': arabicText,
                                      'translation': translation,
                                      'reference':
                                          '${_getSurahDisplayName(ayah)} • Ayah ${ayah['numberInSurah']}',
                                    });
                                    if (!dialogContext.mounted) return;
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text('Bookmark added'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.bookmark_border_rounded,
                                  ),
                                  label: const Text('Bookmark'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.teal,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.maybeOf(
                                      context,
                                    );
                                    await Clipboard.setData(
                                      ClipboardData(
                                        text: '$arabicText\n\n$translation',
                                      ),
                                    );
                                    messenger?.showSnackBar(
                                      const SnackBar(content: Text('Copied')),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded),
                                  label: const Text('Copy'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.teal,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    loadJuzAyahs();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Widget _buildAyahCard(Map<String, dynamic> ayah, {required bool showHeader}) {
    final surahNumber = _getSurahNumber(ayah);
    final showBismillah =
        (ayah['numberInSurah'] as int? ?? 0) == 1 &&
        surahNumber != 1 &&
        surahNumber != 9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              textDirection: TextDirection.ltr,
              children: [
                Text(
                  'Para ${widget.juzNumber}',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _getSurahDisplayName(ayah),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        color: const Color(0xff0f766e),
                        fontWeight: FontWeight.bold,
                        fontSize: showBismillah ? 18 : 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        InkWell(
          onTap: () => showAyahDialog(ayah),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    Text(
                      'AYAH ${ayah['numberInSurah']}',
                      style: TextStyle(
                        color: Colors.teal.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ayah['text'].toString(),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 2,
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageControls() {
    final pageNumber = pages[currentPageIndex].first['page'] as int? ?? 0;
    final isFirstPage = currentPageIndex == 0;
    final isLastPage = currentPageIndex == pages.length - 1;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xff153d37).withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            _PageNavigationButton(
              icon: Icons.arrow_back_rounded,
              label: 'Previous',
              enabled: !isFirstPage,
              onPressed: () => pageController.previousPage(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Container(
                  key: ValueKey(currentPageIndex),
                  margin: const EdgeInsets.symmetric(horizontal: 17),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 28,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffeaf5f2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PAGE $pageNumber',
                        style: const TextStyle(
                          color: Color(0xff0f766e),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currentPageIndex + 1} of ${pages.length}',
                        style: TextStyle(
                          color: Colors.teal.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _PageNavigationButton(
              icon: Icons.arrow_forward_rounded,
              label: 'Next',
              enabled: !isLastPage,
              onPressed: () => pageController.nextPage(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f8f7),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Text(
          'Para ${widget.juzNumber}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : ayahs.isEmpty
          ? const Center(
              child: Text(
                'No ayahs found for this Juz',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Directionality(
              textDirection: TextDirection.ltr,
              child: PageView.builder(
                controller: pageController,
                itemCount: pages.length,
                onPageChanged: (index) =>
                    setState(() => currentPageIndex = index),
                itemBuilder: (context, pageIndex) {
                  final pageAyahs = pages[pageIndex];
                  return ListView.builder(
                    key: PageStorageKey(
                      'juz-${widget.juzNumber}-page-$pageIndex',
                    ),
                    padding: const EdgeInsets.all(16),
                    itemCount: pageAyahs.length,
                    itemBuilder: (context, ayahIndex) {
                      final ayah = pageAyahs[ayahIndex];
                      return _buildAyahCard(
                        ayah,
                        showHeader: _shouldShowSurahHeader(ayahs.indexOf(ayah)),
                      );
                    },
                  );
                },
              ),
            ),
      bottomNavigationBar: !isLoading && pages.isNotEmpty
          ? _buildPageControls()
          : null,
    );
  }
}

class _PageNavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _PageNavigationButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: enabled ? const Color(0xff0f766e) : const Color(0xffdce9e6),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              color: enabled ? Colors.white : const Color(0xff91a9a4),
            ),
          ),
        ),
      ),
    );
  }
}

class Paralist extends StatefulWidget {
  const Paralist({super.key});

  @override
  State<Paralist> createState() => _ParalistState();
}

class _ParalistState extends State<Paralist> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> allParas = [];

  List<Map<String, dynamic>> filteredParas = [];

  bool isLoading = true;

  final List<String> juzArabicNames = [
    'الجزء الأول',
    'الجزء الثاني',
    'الجزء الثالث',
    'الجزء الرابع',
    'الجزء الخامس',
    'الجزء السادس',
    'الجزء السابع',
    'الجزء الثامن',
    'الجزء التاسع',
    'الجزء العاشر',
    'الجزء الحادي عشر',
    'الجزء الثاني عشر',
    'الجزء الثالث عشر',
    'الجزء الرابع عشر',
    'الجزء الخامس عشر',
    'الجزء السادس عشر',
    'الجزء السابع عشر',
    'الجزء الثامن عشر',
    'الجزء التاسع عشر',
    'الجزء العشرون',
    'الجزء الحادي والعشرون',
    'الجزء الثاني والعشرون',
    'الجزء الثالث والعشرون',
    'الجزء الرابع والعشرون',
    'الجزء الخامس والعشرون',
    'الجزء السادس والعشرون',
    'الجزء السابع والعشرون',
    'الجزء الثامن والعشرون',
    'الجزء التاسع والعشرون',
    'الجزء الثلاثون',
  ];

  Future<void> loadParas() async {
    final List<Map<String, dynamic>> loaded = [];

    try {
      for (int i = 1; i <= 30; i++) {
        final url = 'https://api.alquran.cloud/v1/juz/$i/quran-uthmani';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final data = decoded['data'];
          final ayahs = data['ayahs'] as List<dynamic>? ?? [];

          loaded.add({
            'number': i,
            'name': 'Para $i',
            'arabic': juzArabicNames[i - 1],
            'ayahCount': ayahs.length,
          });
        } else {
          loaded.add({
            'number': i,
            'name': 'Para $i',
            'arabic': juzArabicNames[i - 1],
            'ayahCount': 0,
          });
        }
      }
    } catch (e) {
      debugPrint('Juz API error: $e');
      loaded.addAll(
        List.generate(30, (index) {
          final number = index + 1;
          return {
            'number': number,
            'name': 'Juz $number',
            'arabic': juzArabicNames[index],
            'ayahCount': 0,
          };
        }),
      );
    }

    if (!mounted) return;

    setState(() {
      allParas = loaded;
      filteredParas = List.from(allParas);
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();

    loadParas();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f8f7),

      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Para',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),

            child: TextField(
              controller: searchController,

              onChanged: (value) {
                setState(() {
                  filteredParas = allParas.where((para) {
                    return para['number'].toString().contains(value) ||
                        para['name'].toString().toLowerCase().contains(
                          value.toLowerCase(),
                        );
                  }).toList();
                });
              },

              decoration: InputDecoration(
                hintText: 'Search Para...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),

                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            filteredParas = List.from(allParas);
                          });
                        },
                      )
                    : null,

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Total Paras
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),

            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.teal),

                const SizedBox(width: 8),

                Text(
                  '${filteredParas.length} Para',

                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Para List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                : filteredParas.isEmpty
                ? const Center(
                    child: Text(
                      'No Para Found',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),

                    itemCount: filteredParas.length,

                    itemBuilder: (context, index) {
                      final para = filteredParas[index];

                      return Card(
                        elevation: 1,

                        margin: const EdgeInsets.only(bottom: 10),

                        color: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),

                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    JuzDetailScreen(juzNumber: para['number']),
                              ),
                            );
                          },

                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),

                            child: Row(
                              children: [
                                // Para Number
                                Container(
                                  height: 48,
                                  width: 48,

                                  decoration: BoxDecoration(
                                    color: const Color(0xffe7f3f1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),

                                  child: Center(
                                    child: Text(
                                      para['number'].toString(),

                                      style: const TextStyle(
                                        color: Colors.teal,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 14),

                                // Para Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        para['name'],

                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        '${para['ayahCount']} Ayahs',

                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

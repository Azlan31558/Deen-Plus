import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:islamicapp/audio_player_service.dart';

class SurahScreen extends StatefulWidget {
  final Map<String, dynamic> surah;

  const SurahScreen({super.key, required this.surah});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  List<Map<String, dynamic>> ayahs = [];

  bool isLoading = true;

  // Audio player
  final AudioPlayer audioPlayer = sharedAudioPlayer;

  String selectedQari = 'ar.alafasy';

  List<String> audioUrls = [];

  int? currentAyahIndex;

  bool isPlaying = false;
  bool isAudioLoading = false;
  bool isPlayingAll = false;

  StreamSubscription<int?>? indexSubscription;
  StreamSubscription<PlayerState>? playerStateSubscription;
  StreamSubscription<Duration>? positionSubscription;

  final ScrollController scrollController = ScrollController();

  List<GlobalKey> ayahKeys = [];
  List<String> ayahTranslations = [];
  final Set<int> expandedTranslationIndices = {};

  // Qari List
  final List<Map<String, String>> qaris = [
    {'name': 'Mishary Rashid Alafasy', 'id': 'ar.alafasy'},
    {'name': 'Mahmoud Khalil Al-Husary', 'id': 'ar.husary'},
    {'name': 'Mohamed Siddiq Al-Minshawi', 'id': 'ar.minshawi'},
    {'name': 'Abdul Basit Abdul Samad', 'id': 'ar.abdulbasitmurattal'},
    {'name': 'Abdul Rahman Al-Sudais', 'id': 'ar.abdurrahmaansudais'},
  ];

  @override
  void initState() {
    super.initState();

    setupAudioListeners();

    loadSurah();
  }

  // Listen to audio playlist changes
  void setupAudioListeners() {
    indexSubscription = audioPlayer.currentIndexStream.listen((index) {
      if (!mounted) return;

      if (isPlayingAll && index != null) {
        setState(() {
          currentAyahIndex = index;
        });

        scrollToAyah(index);
      }
    });

    playerStateSubscription = audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        isPlaying = state.playing;

        if (state.processingState == ProcessingState.completed) {
          currentAyahIndex = null;
          isPlayingAll = false;
          isPlaying = false;
        }
      });
    });

    positionSubscription = audioPlayer.positionStream.listen((position) {
      if (!mounted) return;

      if (isPlaying && currentAyahIndex != null) {
        setState(() {});
      }
    });
  }

  // Load Surah JSON
  Future<void> loadSurah() async {
    try {
      final int surahNumber = int.parse(widget.surah['number'].toString());

      final String jsonString = await rootBundle.loadString(
        'assets/quran/surah_$surahNumber.json',
      );

      final Map<String, dynamic> data = json.decode(jsonString);

      final Map<String, dynamic> verses = Map<String, dynamic>.from(
        data['verse'],
      );

      List<Map<String, dynamic>> tempAyahs = [];

      verses.forEach((key, value) {
        tempAyahs.add({
          'number': int.parse(key.replaceAll('verse_', '')),
          'text': value.toString(),
        });
      });

      final List<String> emptyTranslations = List.filled(tempAyahs.length, '');

      tempAyahs.sort((a, b) => a['number'].compareTo(b['number']));

      if (!mounted) return;

      setState(() {
        ayahs = tempAyahs;
        ayahKeys = List.generate(ayahs.length, (_) => GlobalKey());
        ayahTranslations = emptyTranslations;
        isLoading = false;
      });

      await loadAyahTranslations();

      // Load selected Qari audio
      await loadQariAudio();
    } catch (e) {
      debugPrint('Error loading Surah: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadAyahTranslations() async {
    try {
      final int surahNumber = int.parse(widget.surah['number'].toString());

      final url = 'https://api.alquran.cloud/v1/surah/$surahNumber/ur.ahmedali';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return;
      }

      final result = jsonDecode(response.body);
      final List<dynamic> apiAyahs = result['data']['ayahs'];
      final Map<int, String> translationMap = {};

      for (var item in apiAyahs) {
        final int number = int.parse(item['numberInSurah'].toString());
        final String text = item['text']?.toString() ?? '';

        if (text.isNotEmpty) {
          translationMap[number] = text;
        }
      }

      if (!mounted) return;

      setState(() {
        ayahTranslations = List.generate(ayahs.length, (index) {
          final int number = int.parse(ayahs[index]['number'].toString());
          return translationMap[number] ?? 'ترجمہ دستیاب نہیں ہے';
        });
      });
    } catch (e) {
      debugPrint('Translation load error: $e');
    }
  }

  // Load audio from selected Qari
  Future<void> loadQariAudio() async {
    if (!mounted) return;

    setState(() {
      isAudioLoading = true;
      audioUrls = [];
    });

    try {
      final int surahNumber = int.parse(widget.surah['number'].toString());

      final url =
          'https://api.alquran.cloud/v1/surah/$surahNumber/$selectedQari';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        final List<dynamic> apiAyahs = result['data']['ayahs'];

        // Match API audio with local Ayah numbers
        final Map<int, String> audioMap = {};

        for (var item in apiAyahs) {
          final int number = int.parse(item['numberInSurah'].toString());

          final String? audio = item['audio']?.toString();

          if (audio != null && audio.isNotEmpty) {
            audioMap[number] = audio;
          }
        }

        String? basmalaAudio;
        if (ayahs.any((ayah) => int.parse(ayah['number'].toString()) == 0)) {
          final basmalaResponse = await http.get(
            Uri.parse('https://api.alquran.cloud/v1/ayah/1/$selectedQari'),
          );
          if (basmalaResponse.statusCode != 200) {
            throw Exception('Bismillah audio API error');
          }

          final basmalaResult = jsonDecode(basmalaResponse.body);
          basmalaAudio = basmalaResult['data']['audio']?.toString();
        }

        final List<String> tempUrls = [];

        for (final ayah in ayahs) {
          final int number = int.parse(ayah['number'].toString());
          final String? audio = number == 0 ? basmalaAudio : audioMap[number];

          if (audio == null || audio.isEmpty) {
            throw Exception(
              'Audio missing for Ayah $number in qari $selectedQari',
            );
          }

          tempUrls.add(audio);
        }

        if (!mounted) return;

        setState(() {
          audioUrls = tempUrls;
          isAudioLoading = false;
        });

        if (tempUrls.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This Qari does not have audio for this surah.'),
            ),
          );
        }
      } else {
        throw Exception('Audio API error');
      }
    } catch (e) {
      debugPrint('Qari audio error: $e');

      if (!mounted) return;

      setState(() {
        isAudioLoading = false;
        audioUrls = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load Qari audio')),
      );
    }
  }

  // Change Qari
  Future<void> changeQari(String? value) async {
    if (value == null) return;

    await stopAudio();

    setState(() {
      selectedQari = value;
    });

    await loadQariAudio();
  }

  // Play one Ayah
  Future<void> playSingleAyah(int index) async {
    if (index >= audioUrls.length) return;

    try {
      await audioPlayer.stop();

      if (!mounted) return;

      setState(() {
        currentAyahIndex = index;
        isPlayingAll = false;
      });

      await audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(audioUrls[index]),
          tag: MediaItem(
            id: '${widget.surah['number']}:${ayahs[index]['number']}',
            album: widget.surah['name']?.toString() ?? 'Quran',
            title: int.parse(ayahs[index]['number'].toString()) == 0
                ? 'بسم الله الرحمن الرحيم'
                : 'Ayah ${ayahs[index]['number']}',
            artist: qaris.firstWhere(
              (qari) => qari['id'] == selectedQari,
            )['name'],
          ),
        ),
      );

      await audioPlayer.play();
    } catch (e) {
      debugPrint('Single Ayah error: $e');
    }
  }

  // Play all Ayahs one by one
  Future<void> playAllAyahs() async {
    if (audioUrls.isEmpty) return;

    try {
      await audioPlayer.stop();

      final List<AudioSource> sources = List.generate(
        audioUrls.length,
        (index) => AudioSource.uri(
          Uri.parse(audioUrls[index]),
          tag: MediaItem(
            id: '${widget.surah['number']}:${ayahs[index]['number']}',
            album: widget.surah['name']?.toString() ?? 'Quran',
            title: int.parse(ayahs[index]['number'].toString()) == 0
                ? 'بسم الله الرحمن الرحيم'
                : 'Ayah ${ayahs[index]['number']}',
            artist: qaris.firstWhere(
              (qari) => qari['id'] == selectedQari,
            )['name'],
          ),
        ),
      );

      setState(() {
        currentAyahIndex = 0;
        isPlayingAll = true;
      });

      await audioPlayer.setAudioSources(
        sources,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );

      await audioPlayer.play();
    } catch (e) {
      debugPrint('Play all error: $e');
    }
  }

  // Stop audio
  Future<void> stopAudio() async {
    await audioPlayer.stop();

    if (!mounted) return;

    setState(() {
      currentAyahIndex = null;
      isPlaying = false;
      isPlayingAll = false;
    });
  }

  int _getHighlightedWordIndex(int ayahIndex) {
    if (currentAyahIndex != ayahIndex || !isPlaying) {
      return -1;
    }

    final String ayahText = ayahs[ayahIndex]['text'].toString();
    final List<String> words = ayahText
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return -1;
    }

    final Duration totalDuration = audioPlayer.duration ?? Duration.zero;
    final Duration elapsed = audioPlayer.position;

    if (totalDuration.inMilliseconds <= 0) {
      return -1;
    }

    final double ratio = (elapsed.inMilliseconds / totalDuration.inMilliseconds)
        .clamp(0.0, 1.0);

    final int wordIndex = (ratio * words.length).floor();

    return wordIndex.clamp(0, words.length - 1);
  }

  // Automatically scroll to currently playing Ayah
  void scrollToAyah(int index) {
    if (index < 0 || index >= ayahKeys.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = ayahKeys[index].currentContext;

      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    });
  }

  @override
  void dispose() {
    indexSubscription?.cancel();
    playerStateSubscription?.cancel();
    positionSubscription?.cancel();

    scrollController.dispose();

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

        title: Text(
          widget.surah['name'].toString(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : ayahs.isEmpty
          ? const Center(
              child: Text('No Ayahs found', style: TextStyle(fontSize: 18)),
            )
          : Column(
              children: [
                // Surah Header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(5),

                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(22),
                  ),

                  child: Column(
                    children: [
                      Text(
                        widget.surah['arabic'].toString(),

                        textDirection: TextDirection.rtl,

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),

                      Text(
                        '${ayahs.length} Ayahs',

                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Qari Selection and Audio Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  child: Row(
                    children: [
                      // Select Qari
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedQari,

                          isExpanded: true,

                          decoration: InputDecoration(
                            labelText: 'Select Qari',
                            prefixIcon: const Icon(
                              Icons.mic,
                              color: Colors.teal,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          items: qaris.map((qari) {
                            return DropdownMenuItem<String>(
                              value: qari['id'],
                              child: Text(
                                qari['name']!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),

                          onChanged: isAudioLoading ? null : changeQari,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Play All
                      IconButton(
                        onPressed: isAudioLoading || audioUrls.isEmpty
                            ? null
                            : playAllAyahs,

                        icon: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.teal,
                          size: 36,
                        ),

                        tooltip: 'Play All Ayahs',
                      ),

                      // Stop
                      IconButton(
                        onPressed: stopAudio,

                        icon: const Icon(
                          Icons.stop_circle,
                          color: Colors.red,
                          size: 34,
                        ),

                        tooltip: 'Stop Audio',
                      ),
                    ],
                  ),
                ),

                if (isAudioLoading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(color: Colors.teal),
                  ),

                const SizedBox(height: 8),

                // All Ayahs
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,

                    padding: const EdgeInsets.symmetric(horizontal: 16),

                    itemCount: ayahs.length,

                    itemBuilder: (context, index) {
                      final ayah = ayahs[index];

                      final bool isActive = currentAyahIndex == index;
                      final List<String> words = ayah['text']
                          .toString()
                          .split(RegExp(r'\s+'))
                          .where((word) => word.trim().isNotEmpty)
                          .toList();
                      final int highlightedWordIndex = _getHighlightedWordIndex(
                        index,
                      );

                      return Container(
                        key: ayahKeys[index],

                        margin: const EdgeInsets.only(bottom: 14),

                        padding: const EdgeInsets.all(18),

                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xffd8efeb)
                              : Colors.white,

                          borderRadius: BorderRadius.circular(20),

                          border: isActive
                              ? Border.all(color: Colors.teal, width: 1.5)
                              : null,

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
                            // Ayah number
                            Row(
                              children: [
                                Container(
                                  height: 38,
                                  width: 38,

                                  decoration: BoxDecoration(
                                    color: const Color(0xffe7f3f1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),

                                  child: Center(
                                    child: Text(
                                      (index + 1).toString(),

                                      style: const TextStyle(
                                        color: Colors.teal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                const Spacer(),

                                // Individual Ayah Play Button
                                IconButton(
                                  onPressed:
                                      isAudioLoading ||
                                          audioUrls.length <= index
                                      ? null
                                      : () {
                                          if (isActive && isPlaying) {
                                            audioPlayer.pause();
                                          } else {
                                            playSingleAyah(index);
                                          }
                                        },

                                  icon: Icon(
                                    isActive && isPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_fill,

                                    color: Colors.teal,
                                    size: 32,
                                  ),

                                  tooltip: 'Play Ayah',
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Arabic Ayah
                            RichText(
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 27,
                                  height: 2,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'serif',
                                  color: Colors.black,
                                ),
                                children: words.asMap().entries.map((entry) {
                                  final int currentWordIndex = entry.key;
                                  final String word = entry.value;
                                  final bool isHighlighted =
                                      isActive &&
                                      highlightedWordIndex == currentWordIndex;

                                  return TextSpan(
                                    text: '$word ',
                                    style: TextStyle(
                                      backgroundColor: isHighlighted
                                          ? Colors.teal.withValues(alpha: 0.18)
                                          : Colors.transparent,
                                      color: isHighlighted
                                          ? Colors.teal.shade900
                                          : Colors.black,
                                      fontWeight: isHighlighted
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            if (ayahTranslations.length > index &&
                                ayahTranslations[index].isNotEmpty)
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (!expandedTranslationIndices.add(
                                            index,
                                          )) {
                                            expandedTranslationIndices.remove(
                                              index,
                                            );
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'ترجمہ',
                                              style: TextStyle(
                                                color: Colors.teal.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              expandedTranslationIndices
                                                      .contains(index)
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              color: Colors.teal.shade700,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (expandedTranslationIndices.contains(
                                      index,
                                    ))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          ayahTranslations[index],
                                          textDirection: TextDirection.rtl,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                            height: 1.7,
                                            fontFamily: 'serif',
                                          ),
                                        ),
                                      ),
                                  ],
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
    );
  }
}

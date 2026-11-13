import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:islamicapp/audio_player_service.dart';

class Mp3PlayerScreen extends StatefulWidget {
  const Mp3PlayerScreen({super.key});

  @override
  State<Mp3PlayerScreen> createState() => _Mp3PlayerScreenState();
}

class _Mp3PlayerScreenState extends State<Mp3PlayerScreen> {
  static const _apiRoot = 'https://mp3quran.net/api/v3';
  static const _teal = Color(0xff008577);

  final AudioPlayer _player = sharedAudioPlayer;
  final FlutterTts _urduSpeaker = FlutterTts();
  final Random _random = Random();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<_QuranSurah> _surahs = [];
  List<_Reciter> _reciters = [];
  _QuranSurah? _selectedSurah;
  _Reciter? _selectedReciter;
  List<_TranslatedAyah> _urduAyahs = [];
  Duration _position = Duration.zero;
  Duration? _duration;
  String? _loadError;
  String? _playbackError;
  bool _isLoadingCatalog = true;
  bool _isLoadingTrack = false;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  bool _handlingCompletion = false;
  bool _screenHasLoadedTrack = false;
  bool _isUrduMode = false;
  bool _isUrduSequenceRunning = false;
  bool _isUrduPaused = false;
  bool _isUrduSpeechActive = false;
  int _currentUrduAyahIndex = 0;
  int _playbackGeneration = 0;
  Completer<void>? _urduResumeCompleter;

  static const List<_Reciter> _availableReciters = [
    _Reciter(
      id: 'mishary',
      apiEdition: 'ar.alafasy',
      name: 'Mishary Rashid Alafasy',
      audioBaseUrl: 'https://cdn.mp3quran.net/audio/mishary-alafasy/r1/',
    ),
    _Reciter(
      id: 'husary',
      apiEdition: 'ar.husary',
      name: 'Mahmoud Khalil Al-Husary',
      audioBaseUrl: 'https://cdn.mp3quran.net/audio/mahmoud-husary/r1/',
    ),
    _Reciter(
      id: 'minshawi',
      apiEdition: 'ar.minshawi',
      name: 'Mohamed Siddiq Al-Minshawi',
      audioBaseUrl: 'https://cdn.mp3quran.net/audio/muhammad-minshawi/r1/',
    ),
    _Reciter(
      id: 'abdulbasit',
      apiEdition: 'ar.abdulbasitmurattal',
      name: 'Abdul Basit Abdul Samad',
      audioBaseUrl: 'https://cdn.mp3quran.net/audio/abdulbasit-abdulsamad/r1/',
    ),
    _Reciter(
      id: 'sudais',
      apiEdition: 'ar.abdurrahmaansudais',
      name: 'Abdul Rahman Al-Sudais',
      audioBaseUrl: 'https://cdn.mp3quran.net/audio/abdulrahman-sudais/r1/',
    ),
    _Reciter(
      id: 'shuraim',
      apiEdition: 'ar.saudalshuraim',
      name: 'Saud Al-Shuraim',
      audioBaseUrl: 'https://cdn.mp3quran.net/audio/saud-shuraim/r1/',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _listenToPlayer();
    unawaited(_loadCatalog());
  }

  void _listenToPlayer() {
    _subscriptions.add(
      _player.positionStream.listen((position) {
        if (mounted) setState(() => _position = position);
      }),
    );
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (mounted) setState(() => _duration = duration);
      }),
    );
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {
          _isPlaying =
              state.playing || (_isUrduSequenceRunning && !_isUrduPaused);
          _isLoadingTrack =
              state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });
        if (state.processingState == ProcessingState.completed &&
            !_isUrduSequenceRunning) {
          unawaited(_playNextAfterCompletion());
        }
      }),
    );
    _subscriptions.add(
      _player.playbackEventStream.listen(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          if (!mounted) return;
          setState(() {
            _playbackError =
                'Unable to play this audio. Please try another reciter or surah.';
            _isLoadingTrack = false;
            _isPlaying = false;
          });
          debugPrint('Quran audio playback error: $error');
        },
      ),
    );
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoadingCatalog = true;
      _loadError = null;
    });

    try {
      final responses = await Future.wait([
        http
            .get(Uri.parse('$_apiRoot/suwar?language=en'))
            .timeout(const Duration(seconds: 20)),
        http
            .get(Uri.parse('$_apiRoot/suwar?language=ar'))
            .timeout(const Duration(seconds: 20)),
      ]);
      for (final response in responses) {
        if (response.statusCode != 200) {
          throw Exception('MP3 Quran API returned ${response.statusCode}.');
        }
      }

      final englishSurahData =
          jsonDecode(responses[0].body) as Map<String, dynamic>;
      final arabicSurahData =
          jsonDecode(responses[1].body) as Map<String, dynamic>;
      final arabicNames = <int, String>{
        for (final item
            in (arabicSurahData['suwar'] as List<dynamic>? ?? [])
                .whereType<Map<String, dynamic>>())
          if (item['id'] is num && item['name'] is String)
            (item['id'] as num).toInt(): (item['name'] as String).trim(),
      };
      final surahs =
          (englishSurahData['suwar'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .where((item) => item['id'] is num && item['name'] is String)
              .map(
                (item) => _QuranSurah(
                  id: (item['id'] as num).toInt(),
                  name: (item['name'] as String).trim(),
                  arabicName: arabicNames[(item['id'] as num).toInt()] ?? '',
                  isMeccan: item['makkia'] == 1 || item['makkia'] == true,
                ),
              )
              .toList()
            ..sort((first, second) => first.id.compareTo(second.id));

      if (surahs.isEmpty) {
        throw const FormatException(
          'The MP3 Quran API returned an empty catalog.',
        );
      }

      if (!mounted) return;
      setState(() {
        _reciters = _availableReciters;
        _surahs = surahs;
        _selectedReciter = _availableReciters.first;
        _selectedSurah = surahs.first;
        _isLoadingCatalog = false;
      });
    } catch (error) {
      debugPrint('Unable to load MP3 Quran catalog: $error');
      if (!mounted) return;
      setState(() {
        _loadError =
            'Could not load the Quran audio catalog. Check your connection and try again.';
        _isLoadingCatalog = false;
      });
    }
  }

  Future<void> _selectReciter(_Reciter reciter) async {
    final wasPlaying = _isPlaying;
    setState(() {
      _selectedReciter = reciter;
    });
    if (_selectedSurah != null) {
      await _playSurah(_selectedSurah!, autoPlay: wasPlaying);
    }
  }

  Future<void> _playSurah(_QuranSurah surah, {bool autoPlay = true}) async {
    final reciter = _selectedReciter;
    if (reciter == null) {
      _showMessage('Choose a reciter before playing a surah.');
      return;
    }

    final generation = ++_playbackGeneration;
    _urduResumeCompleter?.complete();
    _urduResumeCompleter = null;
    _isUrduSequenceRunning = false;
    _isUrduPaused = false;
    _isUrduSpeechActive = false;
    setState(() {
      _selectedSurah = surah;
      _playbackError = null;
      _isLoadingTrack = true;
      _position = Duration.zero;
      _duration = null;
      _handlingCompletion = false;
      _screenHasLoadedTrack = false;
      _currentUrduAyahIndex = 0;
      _urduAyahs = [];
    });
    try {
      await _urduSpeaker.stop();
      await _player.stop();
      if (generation != _playbackGeneration) return;

      if (_isUrduMode) {
        await _loadUrduAyahs(surah, reciter, generation, autoPlay);
        return;
      }

      final url =
          '${reciter.audioBaseUrl}${surah.id.toString().padLeft(3, '0')}.mp3';
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: url,
            title: surah.name,
            artist: reciter.name,
            album: 'The Holy Quran',
          ),
        ),
      );
      await _player.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
      _screenHasLoadedTrack = true;
      if (autoPlay) unawaited(_resumePlayback());
    } catch (error) {
      debugPrint('Unable to load Quran surah audio: $error');
      if (!mounted) return;
      setState(() {
        _playbackError = 'Unable to load this audio. Please try again.';
        _isLoadingTrack = false;
        _isPlaying = false;
      });
    }
  }

  Future<void> _loadUrduAyahs(
    _QuranSurah surah,
    _Reciter reciter,
    int generation,
    bool autoPlay,
  ) async {
    try {
      await _urduSpeaker.setLanguage('ur-PK');
      await _urduSpeaker.setSpeechRate(0.45);
      await _urduSpeaker.awaitSpeakCompletion(true);

      final responses = await Future.wait([
        http
            .get(
              Uri.parse(
                'https://api.alquran.cloud/v1/surah/${surah.id}/${reciter.apiEdition}',
              ),
            )
            .timeout(const Duration(seconds: 25)),
        http
            .get(
              Uri.parse(
                'https://api.alquran.cloud/v1/surah/${surah.id}/ur.ahmedali',
              ),
            )
            .timeout(const Duration(seconds: 25)),
      ]);
      for (final response in responses) {
        if (response.statusCode != 200) {
          throw Exception(
            'Arabic or Urdu audio API returned ${response.statusCode}.',
          );
        }
      }
      if (generation != _playbackGeneration) return;

      final audioData =
          (jsonDecode(responses[0].body) as Map<String, dynamic>)['data']
              as Map<String, dynamic>?;
      final translationData =
          (jsonDecode(responses[1].body) as Map<String, dynamic>)['data']
              as Map<String, dynamic>?;
      final audioAyahs = audioData?['ayahs'] as List<dynamic>? ?? [];
      final translatedAyahs = translationData?['ayahs'] as List<dynamic>? ?? [];
      final expectedAyahCount = int.tryParse(
        audioData?['numberOfAyahs']?.toString() ?? '',
      );
      final translations = <int, String>{};
      for (final ayah in translatedAyahs.whereType<Map<String, dynamic>>()) {
        final number = int.tryParse(ayah['numberInSurah']?.toString() ?? '');
        final text = ayah['text']?.toString().trim() ?? '';
        if (number != null && text.isNotEmpty) translations[number] = text;
      }

      final ayahs = <_TranslatedAyah>[];
      for (final ayah in audioAyahs.whereType<Map<String, dynamic>>()) {
        final number = int.tryParse(ayah['numberInSurah']?.toString() ?? '');
        final audioUrl = ayah['audio']?.toString() ?? '';
        final translation = number == null ? null : translations[number];
        if (number != null &&
            audioUrl.isNotEmpty &&
            translation != null &&
            translation.isNotEmpty) {
          ayahs.add(
            _TranslatedAyah(
              number: number,
              arabicText: ayah['text']?.toString() ?? '',
              urduText: translation,
              audioUrl: audioUrl,
            ),
          );
        }
      }
      if (ayahs.isEmpty ||
          ayahs.length != audioAyahs.length ||
          (expectedAyahCount != null && ayahs.length != expectedAyahCount)) {
        throw const FormatException(
          'No matching Arabic audio and Urdu translations were returned.',
        );
      }

      if (!mounted || generation != _playbackGeneration) return;
      setState(() {
        _urduAyahs = ayahs;
        _isLoadingTrack = false;
      });
      if (autoPlay) unawaited(_runUrduPlayback(generation));
    } catch (error) {
      debugPrint('Unable to prepare Arabic and Urdu playback: $error');
      if (!mounted || generation != _playbackGeneration) return;
      setState(() {
        _playbackError = error is FormatException
            ? 'Ayah-by-ayah audio is unavailable for this reciter. Choose another reciter for Arabic + Urdu playback.'
            : 'Unable to prepare Arabic recitation with Urdu translation. Check your connection and Urdu speech settings.';
        _isLoadingTrack = false;
        _isPlaying = false;
      });
    }
  }

  Future<void> _runUrduPlayback(int generation) async {
    _isUrduSequenceRunning = true;
    _isUrduPaused = false;
    if (mounted) setState(() => _isPlaying = true);
    try {
      while (generation == _playbackGeneration) {
        if (_currentUrduAyahIndex >= _urduAyahs.length) {
          if (_isRepeat) {
            _currentUrduAyahIndex = 0;
          } else {
            _isUrduSequenceRunning = false;
            final nextSurah = _nextAvailableSurah();
            if (nextSurah != null) {
              await _playSurah(nextSurah);
            } else {
              _currentUrduAyahIndex = 0;
              _screenHasLoadedTrack = false;
              if (mounted) setState(() => _isPlaying = false);
            }
            return;
          }
        }

        final ayah = _urduAyahs[_currentUrduAyahIndex];
        await _waitForUrduResume(generation);
        if (generation != _playbackGeneration) return;

        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(ayah.audioUrl),
            tag: MediaItem(
              id: '${_selectedSurah!.id}:${ayah.number}:${_selectedReciter!.id}',
              title: '${_selectedSurah!.name} - Ayah ${ayah.number}',
              artist: _selectedReciter!.name,
              album: 'Arabic recitation and Urdu translation',
            ),
          ),
        );
        _screenHasLoadedTrack = true;
        while (generation == _playbackGeneration) {
          await _waitForUrduResume(generation);
          await _player.play();
          if (generation != _playbackGeneration) return;
          if (_player.processingState == ProcessingState.completed) break;
        }
        if (generation != _playbackGeneration) return;

        await _waitForUrduResume(generation);
        if (ayah.urduText.isNotEmpty) {
          var translationFinished = false;
          while (!translationFinished && generation == _playbackGeneration) {
            await _waitForUrduResume(generation);
            if (mounted) setState(() => _isUrduSpeechActive = true);
            await _urduSpeaker.speak(ayah.urduText);
            if (generation != _playbackGeneration) return;
            if (mounted) setState(() => _isUrduSpeechActive = false);
            translationFinished = !_isUrduPaused;
          }
        }
        _currentUrduAyahIndex++;
      }
    } catch (error) {
      debugPrint('Arabic and Urdu playback failed: $error');
      if (generation == _playbackGeneration && mounted) {
        setState(() {
          _playbackError =
              'Arabic and Urdu playback stopped. Check your audio and Urdu speech settings.';
          _isPlaying = false;
          _isLoadingTrack = false;
          _isUrduSpeechActive = false;
        });
      }
    } finally {
      if (generation == _playbackGeneration) {
        _isUrduSequenceRunning = false;
        if (mounted && !_isUrduPaused) {
          setState(() {
            _isPlaying = false;
            _isUrduSpeechActive = false;
          });
        }
      }
    }
  }

  Future<void> _waitForUrduResume(int generation) async {
    while (_isUrduPaused && generation == _playbackGeneration) {
      final completer = _urduResumeCompleter ??= Completer<void>();
      await completer.future;
    }
  }

  Future<void> _toggleUrduMode(bool enabled) async {
    final surah = _selectedSurah;
    if (surah == null) return;
    final shouldPlay = _isPlaying || _isUrduSpeechActive;
    setState(() {
      _isUrduMode = enabled;
      _playbackError = null;
    });
    await _playSurah(surah, autoPlay: shouldPlay);
  }

  Future<void> _resumePlayback() async {
    try {
      await _player.play();
    } catch (error) {
      debugPrint('Unable to start Quran audio: $error');
      if (!mounted) return;
      setState(() {
        _playbackError = 'Playback failed. Please try again.';
        _isLoadingTrack = false;
        _isPlaying = false;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_selectedSurah == null) return;
    if (_isUrduMode) {
      if (_isUrduSequenceRunning &&
          (!_isUrduPaused || _player.playing || _isUrduSpeechActive)) {
        _isUrduPaused = true;
        await _player.pause();
        await _urduSpeaker.stop();
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isUrduSpeechActive = false;
          });
        }
      } else if (_isUrduSequenceRunning) {
        _isUrduPaused = false;
        final completer = _urduResumeCompleter;
        _urduResumeCompleter = null;
        if (completer != null && !completer.isCompleted) completer.complete();
        if (mounted) setState(() => _isPlaying = true);
      } else if (_urduAyahs.isNotEmpty) {
        unawaited(_runUrduPlayback(_playbackGeneration));
      } else {
        await _playSurah(_selectedSurah!);
      }
      return;
    }
    if (_player.playing) {
      await _player.pause();
    } else if (!_screenHasLoadedTrack) {
      await _playSurah(_selectedSurah!);
    } else {
      await _resumePlayback();
    }
  }

  Future<void> _playNextAfterCompletion() async {
    if (_handlingCompletion ||
        _isUrduSequenceRunning ||
        _isRepeat ||
        _selectedSurah == null) {
      return;
    }
    _handlingCompletion = true;
    final nextSurah = _nextAvailableSurah();
    if (nextSurah != null) await _playSurah(nextSurah);
  }

  _QuranSurah? _nextAvailableSurah({bool previous = false}) {
    final currentIndex = _surahs.indexWhere(
      (surah) => surah.id == _selectedSurah?.id,
    );
    if (currentIndex < 0 || _surahs.isEmpty) return null;
    if (_isShuffle && !previous && _surahs.length > 1) {
      final candidates = _surahs
          .where((surah) => surah.id != _selectedSurah!.id)
          .toList();
      return candidates[_random.nextInt(candidates.length)];
    }
    final nextIndex = currentIndex + (previous ? -1 : 1);
    if (nextIndex < 0 || nextIndex >= _surahs.length) return null;
    return _surahs[nextIndex];
  }

  Future<void> _skip({bool previous = false}) async {
    final surah = _nextAvailableSurah(previous: previous);
    if (surah != null) {
      await _playSurah(surah);
    } else if (previous && _selectedSurah != null) {
      if (_isUrduMode) {
        await _playSurah(_selectedSurah!);
      } else {
        await _player.seek(Duration.zero);
      }
    }
  }

  Future<void> _toggleRepeat() async {
    final repeat = !_isRepeat;
    setState(() => _isRepeat = repeat);
    if (!_isUrduMode) {
      await _player.setLoopMode(repeat ? LoopMode.one : LoopMode.off);
    }
  }

  Future<void> _openReciterPicker() async {
    final selected = await showModalBottomSheet<_Reciter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReciterPicker(reciters: _reciters),
    );
    if (selected != null) await _selectReciter(selected);
  }

  Future<void> _openSurahPlaylist() async {
    final selected = await showModalBottomSheet<_QuranSurah>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SurahPlaylistPicker(
        surahs: _surahs,
        selectedSurahId: _selectedSurah?.id,
      ),
    );
    if (selected != null) await _playSurah(selected);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDuration(Duration? duration) {
    if (duration == null || duration.isNegative) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _playbackGeneration++;
    _urduResumeCompleter?.complete();
    unawaited(_urduSpeaker.stop());
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSurah = _selectedSurah;

    return Scaffold(
      backgroundColor: const Color(0xfff5fbfa),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: const BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    tooltip: 'Back',
                  ),
                  const Expanded(
                    child: Text(
                      'MP3 Quran Player',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                ],
              ),
            ),
            if (_isLoadingCatalog)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_loadError != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 52, color: _teal),
                        const SizedBox(height: 12),
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _loadCatalog,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      _buildReciterSection(),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: _openSurahPlaylist,
                          borderRadius: BorderRadius.circular(14),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.queue_music, color: _teal),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Surah playlist',
                                    style: TextStyle(
                                      color: _teal,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down, color: _teal),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: _buildPlayerCard(selectedSurah)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(_QuranSurah? surah) {
    final durationMs = _duration?.inMilliseconds ?? 0;
    final positionMs = _position.inMilliseconds.clamp(
      0,
      durationMs > 0 ? durationMs : 1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 460;
        return Container(
          padding: EdgeInsets.all(compact ? 12 : 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xffe0f5f1), Color(0xfff5fffd)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _teal.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: compact ? 100 : 145,
                width: compact ? 88 : 120,
                decoration: BoxDecoration(
                  color: const Color(0xff075c50),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xffd9b65d), width: 3),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_stories,
                      color: Color(0xffffd77a),
                      size: 46,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'القرآن الكريم',
                      style: TextStyle(
                        color: Color(0xffffd77a),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'AL QURAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 6 : 14),
              Text(
                surah?.name ?? 'Choose a surah',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (surah != null) ...[
                const SizedBox(height: 3),
                Text(
                  surah.arabicName,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: _teal,
                    fontSize: compact ? 22 : 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              SizedBox(height: compact ? 1 : 4),
              Text(
                _selectedReciter?.name ?? 'Select a reciter',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              FilterChip(
                selected: _isUrduMode,
                showCheckmark: false,
                avatar: Icon(
                  _isUrduMode ? Icons.translate : Icons.record_voice_over,
                  size: 19,
                  color: _teal,
                ),
                label: Text(
                  _isUrduMode ? 'Arabic + Urdu enabled' : 'Play Arabic + Urdu',
                ),
                onSelected: _isLoadingTrack
                    ? null
                    : (enabled) => _toggleUrduMode(enabled),
                selectedColor: const Color(0xffe0f5f1),
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(
                  color: _teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_playbackError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _playbackError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              if (_isUrduMode && _urduAyahs.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Ayah ${_currentUrduAyahIndex.clamp(0, _urduAyahs.length - 1) + 1} of ${_urduAyahs.length} • Urdu follows each Arabic ayah',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxHeight: compact ? 76 : 110),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _urduAyahs[_currentUrduAyahIndex.clamp(
                            0,
                            _urduAyahs.length - 1,
                          )]
                          .urduText,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _teal,
                        fontSize: compact ? 14 : 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
              Slider(
                min: 0,
                max: durationMs > 0 ? durationMs.toDouble() : 1,
                value: positionMs.toDouble(),
                activeColor: _teal,
                onChanged: durationMs <= 0
                    ? null
                    : (value) => setState(
                        () => _position = Duration(milliseconds: value.round()),
                      ),
                onChangeEnd: durationMs <= 0
                    ? null
                    : (value) =>
                          _player.seek(Duration(milliseconds: value.round())),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  Text(_formatDuration(_duration)),
                ],
              ),
              SizedBox(height: compact ? 0 : 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _isShuffle = !_isShuffle),
                    tooltip: 'Shuffle',
                    icon: Icon(
                      Icons.shuffle,
                      color: _isShuffle ? _teal : Colors.grey,
                    ),
                  ),
                  IconButton(
                    onPressed: _surahs.length < 2
                        ? null
                        : () => _skip(previous: true),
                    tooltip: 'Previous surah',
                    icon: Icon(
                      Icons.skip_previous,
                      size: compact ? 30 : 36,
                      color: _teal,
                    ),
                  ),
                  SizedBox(
                    height: compact ? 54 : 64,
                    width: compact ? 54 : 64,
                    child: FilledButton(
                      onPressed: _togglePlayback,
                      style: FilledButton.styleFrom(
                        backgroundColor: _teal,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      child: _isLoadingTrack
                          ? const SizedBox(
                              height: 26,
                              width: 26,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 38,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  IconButton(
                    onPressed: _surahs.length < 2 ? null : _skip,
                    tooltip: 'Next surah',
                    icon: Icon(
                      Icons.skip_next,
                      size: compact ? 30 : 36,
                      color: _teal,
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleRepeat,
                    tooltip: 'Repeat surah',
                    icon: Icon(
                      Icons.repeat_one,
                      color: _isRepeat ? _teal : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (surah != null)
                Text(
                  '${surah.isMeccan ? 'Meccan' : 'Medinan'} • Surah ${surah.id}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReciterSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reciter',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _openReciterPicker,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xffe0f5f1),
                    child: Icon(Icons.mic, color: _teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedReciter?.name ?? 'Select reciter',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahPlaylistPicker extends StatefulWidget {
  const _SurahPlaylistPicker({
    required this.surahs,
    required this.selectedSurahId,
  });

  final List<_QuranSurah> surahs;
  final int? selectedSurahId;

  @override
  State<_SurahPlaylistPicker> createState() => _SurahPlaylistPickerState();
}

class _SurahPlaylistPickerState extends State<_SurahPlaylistPicker> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahs = widget.surahs.where((surah) {
      final query = _query.trim().toLowerCase();
      return query.isEmpty ||
          surah.name.toLowerCase().contains(query) ||
          surah.arabicName.contains(query) ||
          surah.id.toString() == query;
    }).toList();

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: const BoxDecoration(
            color: Color(0xfff5fbfa),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Surah playlist',
                      style: TextStyle(
                        color: _Mp3PlayerScreenState._teal,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text('${widget.surahs.length} surahs'),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search surah',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: _Mp3PlayerScreenState._teal,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: surahs.isEmpty
                    ? const Center(child: Text('No surahs match your search.'))
                    : ListView.builder(
                        itemCount: surahs.length,
                        itemBuilder: (context, index) {
                          final surah = surahs[index];
                          final selected = surah.id == widget.selectedSurahId;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: selected
                                ? const Color(0xffe0f5f1)
                                : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              onTap: () => Navigator.pop(context, surah),
                              leading: CircleAvatar(
                                backgroundColor: selected
                                    ? _Mp3PlayerScreenState._teal
                                    : const Color(0xffedf5f4),
                                child: Text(
                                  '${surah.id}',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : _Mp3PlayerScreenState._teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                surah.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                surah.isMeccan ? 'Meccan' : 'Medinan',
                              ),
                              trailing: Text(
                                surah.arabicName,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  color: _Mp3PlayerScreenState._teal,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UrduTranslationSheet extends StatefulWidget {
  const _UrduTranslationSheet({required this.surah});

  final _QuranSurah surah;

  @override
  State<_UrduTranslationSheet> createState() => _UrduTranslationSheetState();
}

class _UrduTranslationSheetState extends State<_UrduTranslationSheet> {
  List<_TranslatedAyah> _ayahs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTranslation());
  }

  Future<void> _loadTranslation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        http
            .get(
              Uri.parse(
                'https://api.alquran.cloud/v1/surah/${widget.surah.id}/quran-uthmani',
              ),
            )
            .timeout(const Duration(seconds: 25)),
        http
            .get(
              Uri.parse(
                'https://api.alquran.cloud/v1/surah/${widget.surah.id}/ur.ahmedali',
              ),
            )
            .timeout(const Duration(seconds: 25)),
      ]);

      for (final response in responses) {
        if (response.statusCode != 200) {
          throw Exception('Translation API returned ${response.statusCode}.');
        }
      }

      final arabicData =
          (jsonDecode(responses[0].body) as Map<String, dynamic>)['data']
              as Map<String, dynamic>?;
      final translationData =
          (jsonDecode(responses[1].body) as Map<String, dynamic>)['data']
              as Map<String, dynamic>?;
      final arabicAyahs = arabicData?['ayahs'] as List<dynamic>? ?? [];
      final translatedAyahs = translationData?['ayahs'] as List<dynamic>? ?? [];
      if (arabicAyahs.isEmpty || translatedAyahs.isEmpty) {
        throw const FormatException(
          'No translation was returned for this surah.',
        );
      }

      final translatedByNumber = <int, String>{};
      for (final item in translatedAyahs.whereType<Map<String, dynamic>>()) {
        final number = int.tryParse(item['numberInSurah']?.toString() ?? '');
        if (number != null) {
          translatedByNumber[number] = item['text']?.toString() ?? '';
        }
      }
      final parsedAyahs = arabicAyahs
          .whereType<Map<String, dynamic>>()
          .map((ayah) {
            final number =
                int.tryParse(ayah['numberInSurah']?.toString() ?? '') ?? 0;
            return _TranslatedAyah(
              number: number,
              arabicText: ayah['text']?.toString() ?? '',
              urduText: translatedByNumber[number] ?? '',
            );
          })
          .where(
            (ayah) => ayah.arabicText.isNotEmpty || ayah.urduText.isNotEmpty,
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _ayahs = parsedAyahs;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Unable to load Urdu surah translation: $error');
      if (!mounted) return;
      setState(() {
        _error =
            'Unable to load this Urdu translation. Check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          decoration: const BoxDecoration(
            color: Color(0xfff5fbfa),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.surah.arabicName,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: _Mp3PlayerScreenState._teal,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.surah.name} • Urdu translation',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: _Mp3PlayerScreenState._teal,
                        ),
                      )
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _loadTranslation,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try again'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _ayahs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final ayah = _ayahs[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xffe0f5f1),
                                    child: Text(
                                      '${ayah.number}',
                                      style: const TextStyle(
                                        color: _Mp3PlayerScreenState._teal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  ayah.arabicText,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    height: 1.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ayah.urduText,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    height: 1.7,
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
      ),
    );
  }
}

class _TranslatedAyah {
  const _TranslatedAyah({
    required this.number,
    required this.arabicText,
    required this.urduText,
    this.audioUrl = '',
  });

  final int number;
  final String arabicText;
  final String urduText;
  final String audioUrl;
}

class _ReciterPicker extends StatefulWidget {
  const _ReciterPicker({required this.reciters});

  final List<_Reciter> reciters;

  @override
  State<_ReciterPicker> createState() => _ReciterPickerState();
}

class _ReciterPickerState extends State<_ReciterPicker> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reciters = widget.reciters
        .where((reciter) => reciter.name.toLowerCase().contains(_query))
        .toList();

    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.78,
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a reciter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search reciters',
                prefixIcon: const Icon(
                  Icons.search,
                  color: _Mp3PlayerScreenState._teal,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: reciters.isEmpty
                  ? const Center(child: Text('No reciters found.'))
                  : ListView.builder(
                      itemCount: reciters.length,
                      itemBuilder: (context, index) {
                        final reciter = reciters[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xffe0f5f1),
                            child: Icon(
                              Icons.mic,
                              color: _Mp3PlayerScreenState._teal,
                            ),
                          ),
                          title: Text(reciter.name),
                          onTap: () => Navigator.pop(context, reciter),
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

class _QuranSurah {
  const _QuranSurah({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.isMeccan,
  });

  final int id;
  final String name;
  final String arabicName;
  final bool isMeccan;
}

class _Reciter {
  const _Reciter({
    required this.id,
    required this.apiEdition,
    required this.name,
    required this.audioBaseUrl,
  });

  final String id;
  final String apiEdition;
  final String name;
  final String audioBaseUrl;
}

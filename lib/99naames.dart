// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:islamicapp/audio_player_service.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class AllahName {
  final int id;
  final String arabic;
  final String transliteration;
  final String urduMeaning;
  final double startSeconds;

  const AllahName({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.urduMeaning,
    required this.startSeconds,
  });
}

const _namesTimestampUrl =
    'https://raw.githubusercontent.com/MuhammadAhsan-Shafiq/99-Names-of-Allah-JSON/main/99NamesOfAllah.json';
const _namesVideoId = 'ta_tTZrarE0';

List<AllahName> _cachedAllahNames = [];

class Names99Screen extends StatefulWidget {
  const Names99Screen({super.key});

  @override
  State<Names99Screen> createState() => _Names99ScreenState();
}

class _Names99ScreenState extends State<Names99Screen> {
  final Color _bgColor = const Color(0xFFE8F2F2);
  final Color _primaryTeal = Colors.teal;
  final Color _goldAccent = const Color(0xFFD4AF37);

  List<AllahName> _filteredNames = [];
  bool _isLoading = true;
  String? _loadError;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNamesOnce();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNamesOnce() async {
    if (_cachedAllahNames.isNotEmpty) {
      setState(() {
        _filteredNames = _cachedAllahNames;
        _isLoading = false;
        _loadError = null;
      });
      return;
    }

    try {
      final responses = await Future.wait([
        rootBundle.loadString('assets/quran/asma-ul-husna (1).json'),
        http
            .get(Uri.parse(_namesTimestampUrl))
            .timeout(const Duration(seconds: 20)),
      ]);
      final List<dynamic> localJson = jsonDecode(responses[0] as String);
      final timestampResponse = responses[1] as http.Response;
      if (timestampResponse.statusCode != 200) {
        throw Exception(
          'Names timestamp API returned ${timestampResponse.statusCode}.',
        );
      }

      final List<dynamic> timestampJson =
          jsonDecode(timestampResponse.body) as List<dynamic>;
      if (timestampJson.length != 99 || localJson.length != 99) {
        throw const FormatException(
          'The names data must contain exactly 99 entries.',
        );
      }

      final localNames = <int, Map<String, dynamic>>{
        for (final item in localJson.whereType<Map<String, dynamic>>())
          if (item['id'] is num) (item['id'] as num).toInt(): item,
      };
      final loaded = timestampJson.map((item) {
        if (item is! Map<String, dynamic> ||
            item['number'] is! num ||
            item['name'] is! String ||
            item['transliteration'] is! String ||
            item['start'] is! num) {
          throw const FormatException('Invalid names timestamp entry.');
        }

        final id = (item['number'] as num).toInt();
        final localName = localNames[id];
        final startSeconds = (item['start'] as num).toDouble();
        if (localName == null || !startSeconds.isFinite || startSeconds < 0) {
          throw FormatException(
            'Names timestamp data does not match name $id.',
          );
        }
        return AllahName(
          id: id,
          arabic: item['name'] as String,
          transliteration: item['transliteration'] as String,
          urduMeaning: localName['urduMeaning'] as String? ?? '',
          startSeconds: startSeconds,
        );
      }).toList();
      if (loaded.first.id != 1 || loaded.last.id != 99) {
        throw const FormatException('Names data must be numbered 1 to 99.');
      }
      for (var index = 1; index < loaded.length; index++) {
        if (loaded[index].id <= loaded[index - 1].id ||
            loaded[index].startSeconds <= loaded[index - 1].startSeconds) {
          throw const FormatException(
            'Names timestamps must be in ascending order.',
          );
        }
      }

      _cachedAllahNames = loaded;

      if (mounted) {
        setState(() {
          _filteredNames = _cachedAllahNames;
          _isLoading = false;
          _loadError = null;
        });
      }
    } catch (error) {
    debugPrint('Unable to load 99 names and timestamps: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError =
              'Could not load the names and audio sync data. Check your connection and try again.';
        });
      }
    }
  }

  void _filterNames(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _filteredNames = _cachedAllahNames;
      });
      return;
    }

    setState(() {
      _filteredNames = _cachedAllahNames.where((item) {
        return item.arabic.contains(query) ||
            item.transliteration.toLowerCase().contains(q) ||
            item.urduMeaning.contains(query) ||
            item.id.toString() == q;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTopBanner(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_primaryTeal),
                      ),
                    )
                  : _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _loadError!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _loadError = null;
                                });
                                _loadNamesOnce();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _filteredNames.isEmpty
                  ? _buildEmpty()
                  : _buildNamesGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: _primaryTeal, size: 20),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryTeal,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _primaryTeal.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome, color: _goldAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "99 Names of Allah",
                  style: GoogleFonts.poppins(
                    color: _primaryTeal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "أسماء الله الحسنى",
                  style: GoogleFonts.amiri(
                    color: _primaryTeal,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
         
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryTeal, _primaryTeal.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _primaryTeal.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded, color: _goldAccent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "Hadith (Sahih Bukhari)",
                      style: GoogleFonts.poppins(
                        color: _goldAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "\"Allah has 99 names; whoever memorizes them will enter Paradise.\"",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: _goldAccent.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Text(
              "99",
              style: GoogleFonts.poppins(
                color: _goldAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
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
          border: Border.all(color: Colors.teal.shade100),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filterNames,
          style: GoogleFonts.poppins(color: _primaryTeal, fontSize: 13),
          decoration: InputDecoration(
            hintText: "Search by number, Arabic, or meaning...",
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
            prefixIcon: Icon(Icons.search, color: _primaryTeal, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade500,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _filterNames("");
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildNamesGrid() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: _filteredNames.length,
      itemBuilder: (context, index) {
        final name = _filteredNames[index];
        final originalIndex = _cachedAllahNames.indexWhere(
          (item) => item.id == name.id,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.teal.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.shade900.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () =>
                _openDetailScreen(originalIndex >= 0 ? originalIndex : 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _primaryTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _primaryTeal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "${name.id}",
                        style: GoogleFonts.poppins(
                          color: _primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.transliteration,
                          style: GoogleFonts.poppins(
                            color: _primaryTeal,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name.urduMeaning,
                          style: GoogleFonts.notoNastaliqUrdu(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    name.arabic,
                    style: GoogleFonts.amiri(
                      color: _primaryTeal,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: _primaryTeal.withValues(alpha: 0.4),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "No Name of Allah found",
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _openDetailScreen(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NamesDetailAudioScreen(initialIndex: index),
      ),
    );
  }
}

// Plays the supplied recitation and follows its per-name timestamps.
class NamesDetailAudioScreen extends StatefulWidget {
  final int initialIndex;

  const NamesDetailAudioScreen({super.key, required this.initialIndex});

  @override
  State<NamesDetailAudioScreen> createState() => _NamesDetailAudioScreenState();
}

class _NamesDetailAudioScreenState extends State<NamesDetailAudioScreen>
    with SingleTickerProviderStateMixin {
  late final YoutubePlayerController _youtubeController;
  late int _currentIndex;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isPlaying = false;
  bool _isLoadingAudio = true;
  String? _playbackError;
  StreamSubscription<YoutubeVideoState>? _positionSubscription;
  StreamSubscription<YoutubePlayerValue>? _playerStateSubscription;

  final Color _bgColor = const Color(0xFFE8F2F2);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex
        .clamp(0, _cachedAllahNames.length - 1)
        .toInt();
    final initialName = _cachedAllahNames[_currentIndex];
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: _namesVideoId,
      autoPlay: true,
      startSeconds: initialName.startSeconds,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: false,
        interfaceLanguage: 'en',
        videoStateUpdateInterval: 250,
      ),
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _animController.forward();
    unawaited(sharedAudioPlayer.stop());
    _positionSubscription = _youtubeController.videoStateStream.listen(
      (state) => _syncNameToPosition(state.position),
      onError: _handlePlaybackError,
    );
    _playerStateSubscription = _youtubeController.listen((value) {
      if (!mounted) return;
      setState(() {
        _isPlaying = value.playerState == PlayerState.playing;
        _isLoadingAudio =
            value.playerState == PlayerState.buffering ||
            value.playerState == PlayerState.unStarted;
        if (value.playerState == PlayerState.playing) {
          _playbackError = null;
        }
      });
    }, onError: _handlePlaybackError);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    unawaited(_youtubeController.close());
    _animController.dispose();
    super.dispose();
  }

  Future<void> _syncNameToPosition(Duration position) async {
    if (!mounted || _cachedAllahNames.isEmpty) return;

    final seconds = position.inMicroseconds / Duration.microsecondsPerSecond;
    final currentName = _cachedAllahNames[_currentIndex];
    final currentStart = currentName.startSeconds;
    final nextNameStart = _currentIndex + 1 < _cachedAllahNames.length
        ? _cachedAllahNames[_currentIndex + 1].startSeconds
        : null;

    if (seconds < currentStart - 0.5) {
      await _youtubeController.seekTo(
        seconds: currentStart,
        allowSeekAhead: true,
      );
      return;
    }

    if (nextNameStart != null && seconds >= nextNameStart - 0.15) {
      final nextIndex = _currentIndex + 1;
      if (nextIndex < _cachedAllahNames.length) {
        await _seekToName(nextIndex);
      }
      return;
    }

    if (!_isPlaying) return;

    var matchingIndex = _currentIndex;
    for (var index = 0; index < _cachedAllahNames.length; index++) {
      final candidate = _cachedAllahNames[index];
      final nextStart = index + 1 < _cachedAllahNames.length
          ? _cachedAllahNames[index + 1].startSeconds
          : double.infinity;
      if (seconds >= candidate.startSeconds && seconds < nextStart) {
        matchingIndex = index;
        break;
      }
    }

    if (matchingIndex == _currentIndex) return;

    setState(() => _currentIndex = matchingIndex);
    _animController.forward(from: 0.0);
  }

  void _handlePlaybackError(Object error) {
    debugPrint('99 names YouTube playback error: $error');
    if (!mounted) return;
    setState(() {
      _isLoadingAudio = false;
      _isPlaying = false;
      _playbackError =
          'Unable to play the recitation. Check your connection or open it on YouTube.';
    });
  }

  Future<void> _seekToName(int index) async {
    if (index < 0 || index >= _cachedAllahNames.length) return;
    setState(() => _currentIndex = index);
    _animController.forward(from: 0.0);
    await _youtubeController.seekTo(
      seconds: _cachedAllahNames[index].startSeconds,
      allowSeekAhead: true,
    );
  }

  Future<void> _goToNextName() async {
    if (_currentIndex < _cachedAllahNames.length - 1) {
      await _seekToName(_currentIndex + 1);
    }
  }

  Future<void> _goToPreviousName() async {
    if (_currentIndex > 0) await _seekToName(_currentIndex - 1);
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _youtubeController.pauseVideo();
      return;
    }

    final currentName = _cachedAllahNames[_currentIndex];
    final currentPosition = Duration(
      milliseconds: (await _youtubeController.currentTime * 1000).round(),
    );
    final nextNameStart = _currentIndex + 1 < _cachedAllahNames.length
        ? _cachedAllahNames[_currentIndex + 1].startSeconds
        : null;

    if (currentPosition.inSeconds.toDouble() < currentName.startSeconds - 0.5 ||
        (nextNameStart != null &&
            currentPosition.inSeconds.toDouble() >= nextNameStart - 0.1)) {
      await _youtubeController.seekTo(
        seconds: currentName.startSeconds,
        allowSeekAhead: true,
      );
    }

    await _youtubeController.playVideo();
  }

  Future<void> _stopReading() async {
    await _youtubeController.pauseVideo();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedAllahNames.isEmpty) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentName = _cachedAllahNames[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFE8F2F2),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F2F2),
              Color(0xFFF3EFE8),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                          radius: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 8),
                  _buildTopBar(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      children: [
                        IgnorePointer(
                          child: Opacity(
                            opacity: 0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: YoutubePlayer(
                                controller: _youtubeController,
                                aspectRatio: 16 / 9,
                              ),
                            ),
                          ),
                        ),
                        if (_playbackError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _playbackError!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: GestureDetector(
                              onTap: _goToNextName,
                              onHorizontalDragEnd: (details) {
                                if ((details.primaryVelocity ?? 0) < 0) {
                                  _goToNextName();
                                } else if ((details.primaryVelocity ?? 0) > 0) {
                                  _goToPreviousName();
                                }
                              },
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: _buildMainNameCard(currentName),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPlayerControls(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.teal, size: 22),
            onPressed: () {
              unawaited(_stopReading());
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Asma-ul-Husna",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      color:  Colors.teal,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "Recitation",
                    style: GoogleFonts.poppins(
                      color:  Colors.teal,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: "Stop reading",
            icon: const Icon(
              Icons.stop_circle_outlined,
              color: Colors.teal,
              size: 26,
            ),
            onPressed: _stopReading,
          ),
        ],
      ),
    );
  }

  Widget _buildMainNameCard(AllahName name) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFE8),
        borderRadius: BorderRadius.circular(30),
         boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3EC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:   Colors.teal.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  name.arabic,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    color: const Color(0xFF0B6A65),
                    fontSize: 58,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name.transliteration,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0B6A65),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: Divider(color:   Colors.teal, thickness: 1.2),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.star_rounded, color:   Colors.teal, size: 18),
              ),
              Expanded(
                child: Divider(color:   Colors.teal, thickness: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            name.urduMeaning,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoNastaliqUrdu(
              color: const Color(0xFF0B3F45),
              fontSize: 22,
              height: 1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                color: const Color(0xFF0B6A65),
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                "Tap for next name",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF0B6A65),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F8A84), Color(0xFF0B6C66)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.volume_up_rounded, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Name ${name.id} of ${_cachedAllahNames.length}",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPlayerControls() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F8A84), Color(0xFF0B6C66)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color:  Colors.teal, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            iconSize: 36,
            color: const Color(0xFFF3C96C),
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: _goToPreviousName,
          ),
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE5C56B),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isLoadingAudio
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0B6C66),
                          ),
                        ),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: const Color(0xFF0B6C66),
                        size: 40,
                      ),
              ),
            ),
          ),
          IconButton(
            iconSize: 36,
            color: const Color(0xFFF3C96C),
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: _goToNextName,
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class IslamicAiScreen extends StatefulWidget {
  const IslamicAiScreen({super.key});

  @override
  State<IslamicAiScreen> createState() => _IslamicAiScreenState();
}

class _IslamicAiScreenState extends State<IslamicAiScreen> {
  // Optional Gemini API Key
  String apiKey = "";

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _suggestedPrompts = [
    "What are the 5 Pillars of Islam?",
    "Explain the importance of Tahajjud prayer",
    "Duas for seeking forgiveness (Istighfar)",
    "What is the significance of Ramadan?",
    "Tell me about Prophet Muhammad's (PBUH) character",
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text:
            "As-salamu alaykum (السلام عليكم)! I am your Islamic AI Assistant. You can ask me any question related to the Holy Quran, Hadith, prayers, Duas, Islamic history, or daily Islamic guidance.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? customPrompt}) async {
    final prompt = (customPrompt ?? _textController.text).trim();
    if (prompt.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          text: prompt,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    // Answer retrieval with zero network crashes
    final answer = await _resolveIslamicQuestion(prompt);

    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: answer,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<String> _resolveIslamicQuestion(String query) async {
    // 1. If user set their own Gemini API key, try Gemini first
    if (apiKey.trim().isNotEmpty) {
      try {
        final geminiResp = await _fetchFromGemini(query, apiKey.trim());
        if (geminiResp != null && geminiResp.isNotEmpty) {
          return geminiResp;
        }
      } catch (_) {}
    }

    // 2. Try online Quranic Knowledge Engine (api.quran.com)
    try {
      final quranResult = await _fetchFromQuranApi(query);
      if (quranResult != null && quranResult.isNotEmpty) {
        return quranResult;
      }
    } catch (_) {}

    // 3. Comprehensive Islamic Knowledge Intelligence Base
    return _getIntelligentIslamicResponse(query);
  }

  // --- Live Quran API Search ---
  Future<String?> _fetchFromQuranApi(String query) async {
    final cleanQuery = query
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
    if (cleanQuery.isEmpty) return null;

    final words = cleanQuery.split(' ');
    // Filter out common stop words to find the main Islamic subject
    final stopWords = {
      'what', 'is', 'are', 'the', 'of', 'in', 'and', 'to', 'how', 'about',
      'tell', 'me', 'explain', 'importance', 'significance', 'can', 'you', 'a', 'an'
    };
    final keywords = words.where((w) => !stopWords.contains(w.toLowerCase())).toList();
    final searchWord = keywords.isNotEmpty ? keywords.first : cleanQuery;

    final url = Uri.parse('https://api.quran.com/api/v4/search?q=${Uri.encodeComponent(searchWord)}&size=3');
    final response = await http.get(url).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['search']?['results'] as List?;
      if (results != null && results.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln("✨ Quranic Guidance on \"$query\":\n");

        for (var i = 0; i < results.length && i < 2; i++) {
          final item = results[i];
          final verseKey = item['verse_key'] ?? '';
          final arabicText = item['text'] ?? '';
          final translations = item['translations'] as List?;
          String englishText = '';
          if (translations != null && translations.isNotEmpty) {
            englishText = translations[0]['text'] ?? '';
            // Remove html tags if any
            englishText = englishText.replaceAll(RegExp(r'<[^>]*>'), '');
          }

          buffer.writeln("📖 Surah $verseKey:");
          if (arabicText.isNotEmpty) {
            buffer.writeln("$arabicText\n");
          }
          if (englishText.isNotEmpty) {
            buffer.writeln("\"$englishText\"\n");
          }
        }

        final commentary = _getTopicCommentary(query);
        if (commentary.isNotEmpty) {
          buffer.writeln(commentary);
        }
        return buffer.toString().trim();
      }
    }
    return null;
  }

  // --- Gemini API Call ---
  Future<String?> _fetchFromGemini(String prompt, String key) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {
                "text":
                    "You are a wise and authentic Islamic AI Assistant. Answer this Islamic question with Quran and Sunnah references: $prompt"
              }
            ]
          }
        ]
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString().trim();
    }
    return null;
  }

  // --- Comprehensive Comprehensive Islamic Intelligent Knowledge Base ---
  String _getIntelligentIslamicResponse(String question) {
    final q = question.toLowerCase();

    if (q.contains("pillar") || q.contains("arkan") || q.contains("five")) {
      return "The 5 Pillars of Islam (أركان الإسلام) are the foundation of a Muslim's faith and practice:\n\n"
          "1. Shahadah (Faith): Professing that \"There is no deity except Allah, and Muhammad (PBUH) is His Messenger.\"\n"
          "2. Salah (Prayer): Performing the five daily prayers at their prescribed times facing the Kaaba.\n"
          "3. Zakat (Almsgiving): Obligatory charity of 2.5% on qualifying accumulated wealth to help the poor and needy.\n"
          "4. Sawm (Fasting): Fasting during the holy month of Ramadan from dawn until dusk.\n"
          "5. Hajj (Pilgrimage): Journeying to Makkah to perform sacred rites at least once in a lifetime for those physically and financially able.";
    }

    if (q.contains("tahajjud") || q.contains("night prayer") || q.contains("qiyam")) {
      return "Importance of Tahajjud (Qiyam al-Layl):\n\n"
          "• Noble Status: It is the most virtuous voluntary prayer after the obligatory prayers.\n"
          "• Quranic Reference: \"And from [part of] the night, pray with it as additional [worship] for you; it is expected that your Lord will resurrect you to a praised station.\" (Surah Al-Isra 17:79)\n"
          "• Hadith: Prophet Muhammad (PBUH) said: 'The Lord descends every night to the lowest heaven during the last third of the night and asks: Who is calling upon Me that I may answer him? Who is asking of Me that I may give him? Who is seeking My forgiveness that I may forgive him?' (Sahih Bukhari & Muslim)\n"
          "• Best Time: In the last third of the night before Fajr prayer.";
    }

    if (q.contains("forgiveness") || q.contains("istighfar") || q.contains("tawbah") || q.contains("dua")) {
      return "Duas for Forgiveness (Istighfar):\n\n"
          "1. Sayyid al-Istighfar (The Master Dua for Forgiveness):\n"
          "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ...\n"
          "\"Allahumma anta Rabbi la ilaha illa anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika mastata'tu...\"\n\n"
          "2. Daily Istighfar:\n"
          "\"Astaghfirullah al-'Azim al-ladhi la ilaha illa Huwal-Hayyul-Qayyum wa atubu ilayh.\"\n"
          "(I seek the forgiveness of Allah the Magnificent, none has the right to be worshipped except Him, the Ever-Living, the Sustainer, and I turn to Him in repentance.)\n\n"
          "Allah says in the Quran: \"Indeed, Allah forgives all sins. Indeed, it is He who is the Forgiving, the Merciful.\" (Surah Az-Zumar 39:53)";
    }

    if (q.contains("ramadan") || q.contains("roza") || q.contains("fasting")) {
      return "The Significance of Ramadan:\n\n"
          "• Revelation of the Holy Quran: Ramadan is the holy month in which the Quran was revealed as guidance for mankind (Surah Al-Baqarah 2:185).\n"
          "• Laylatul Qadr: Within Ramadan lies the Night of Decree (Laylatul Qadr), which is better than 1,000 months of worship (Surah Al-Qadr).\n"
          "• Cleansing of Sins: The Prophet (PBUH) said: 'Whoever fasts Ramadan out of faith and expecting reward, his previous sins will be forgiven.' (Sahih Bukhari)\n"
          "• Spiritual Purpose: Fasting cultivates Taqwa (God-consciousness), empathy for the needy, and self-restraint.";
    }

    if (q.contains("prophet") || q.contains("muhammad") || q.contains("character") || q.contains("seerah") || q.contains("nabi")) {
      return "Character & Virtues of Prophet Muhammad (PBUH):\n\n"
          "• Allah's Testimony in the Quran: \"And indeed, you are of a great moral character.\" (Surah Al-Qalam 68:4)\n"
          "• Mercy to All Creation: \"And We have not sent you, [O Muhammad], except as a mercy to the worlds.\" (Surah Al-Anbiya 21:107)\n"
          "• Living Quran: When asked about his conduct, Hazrat Aisha (R.A) answered: \"His character was the Quran.\" (Sahih Muslim)\n"
          "• Qualities: He was renowned as As-Sadiq (the Truthful) and Al-Amin (the Trustworthy) throughout his blessed life.";
    }

    if (q.contains("salah") || q.contains("namaz") || q.contains("prayer") || q.contains("wudu")) {
      return "Importance of Salah (Namaz) in Islam:\n\n"
          "• Second Pillar: Salah is the foremost act of worship and the distinction of a believer.\n"
          "• Quranic Order: \"Indeed, prayer has been decreed upon the believers a decree of specified times.\" (Surah An-Nisa 4:103)\n"
          "• First Question on Judgment Day: The Messenger of Allah (PBUH) said: 'The first matter that the slave will be brought to account for on the Day of Judgment is the prayer. If it is sound, then the rest of his deeds will be sound.' (At-Tirmidhi)\n"
          "• Five Daily Times: Fajr (Dawn), Dhuhr (Noon), Asr (Afternoon), Maghrib (Sunset), and Isha (Night).";
    }

    if (q.contains("zakat") || q.contains("zakah") || q.contains("charity") || q.contains("sadqah")) {
      return "Zakat & Sadaqah in Islam:\n\n"
          "• Zakat: An obligatory 2.5% contribution upon wealth exceeding the Nisab threshold (cash, gold, silver, investments) held for one full lunar year.\n"
          "• Quranic Injunction: \"Establish prayer and give Zakat, and whatever good you put forward for yourselves - you will find it with Allah.\" (Surah Al-Baqarah 2:110)\n"
          "• Purpose: It purifies wealth and protects society by uplifting orphans, the poor, and the destitute.\n"
          "• Sadaqah: Voluntary charity given anytime. The Prophet (PBUH) taught that even a smile or removing a harmful object from the road is Sadaqah.";
    }

    if (q.contains("parent") || q.contains("mother") || q.contains("father") || q.contains("walidayn")) {
      return "Rights of Parents in Islam:\n\n"
          "• High Station: Allah commands kindness to parents right after monotheism (Tawhid): \"And your Lord has decreed that you not worship except Him, and to parents, good treatment.\" (Surah Al-Isra 17:23)\n"
          "• Mother's Honour: A man asked Prophet Muhammad (PBUH): 'Who is most worthy of my good companionship?' The Prophet replied: 'Your mother, then your mother, then your mother, then your father.' (Sahih Bukhari)\n"
          "• Never say 'Uff': Do not disrespect or speak harshly to them, especially in their old age.";
    }

    if (q.contains("patience") || q.contains("sabr") || q.contains("hardship") || q.contains("trial")) {
      return "Sabr (Patience & Perseverance) in Islam:\n\n"
          "• Divine Promise: \"Indeed, Allah is with the patient.\" (Surah Al-Baqarah 2:153)\n"
          "• Endless Reward: \"Indeed, the patient will be given their reward without account.\" (Surah Az-Zumar 39:10)\n"
          "• The Prophet (PBUH) stated: 'No one has been given a blessing greater and more expansive than patience.' (Sahih Bukhari)";
    }

    if (q.contains("kalima") || q.contains("kalma") || q.contains("shahada")) {
      return "The Six Kalimas in Islam:\n\n"
          "1. Kalima Tayyibah: لَا إِلٰهَ إِلَّا الله مُحَمَّدٌ رَّسُولُ الله\n"
          "\"There is no deity worthy of worship except Allah, and Muhammad is the Messenger of Allah.\"\n\n"
          "2. Kalima Shahadah: أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ\n"
          "3. Kalima Tamjeed: سُبْحَان اللهِ وَالْحَمْدُ لِلّهِ وَلَا اِلهَ اِلَّا اللّهُ وَاللّهُ اَكْبَرُ...\n"
          "4. Kalima Tawheed: لَا إِلٰهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ...\n"
          "5. Kalima Istighfar: اَسْتَغْفِرُ اللهَ رَبِّىْ مِنْ كُلِّ ذَنْۢبٍ...\n"
          "6. Kalima Radde Kufr: اللّهُمَّ إنِّي أَعُوذُ بِكَ مِنْ أَنْ أُشْرِكَ بِكَ...";
    }

    // Dynamic Islamic Guidance for other questions
    return "Regarding your question:\n\n\"$question\"\n\n"
        "Guidance from Quran & Sunnah:\n"
        "• Seeking Islamic knowledge is an obligation upon every believer: The Messenger of Allah (PBUH) said: 'Seeking knowledge is obligatory upon every Muslim.' (Sunan Ibn Majah)\n"
        "• Always turn to the Holy Quran and authentic Hadiths of the Prophet (PBUH) for reliable rulings.\n"
        "• In matters of specific daily rulings or personal legal queries, it is recommended to also consult a trustworthy local Islamic scholar.";
  }

  String _getTopicCommentary(String q) {
    final query = q.toLowerCase();
    if (query.contains("mercy")) {
      return "Hadith: Prophet Muhammad (PBUH) said: 'Those who are merciful will be shown mercy by the Most Merciful. Be merciful to those on the earth and the One in the heavens will have mercy upon you.' (Sunan At-Tirmidhi)";
    }
    if (query.contains("parent")) {
      return "Hadith: Prophet Muhammad (PBUH) said: 'The pleasure of the Lord lies in the pleasure of the parents, and the wrath of the Lord lies in the wrath of the parents.' (At-Tirmidhi)";
    }
    if (query.contains("patience") || query.contains("sabr")) {
      return "Hadith: Prophet Muhammad (PBUH) said: 'Wondrous is the affair of the believer, for there is good for him in every matter; if good comes to him, he thanks Allah, and if trial comes to him, he observes patience, which is good for him.' (Sahih Muslim)";
    }
    return "";
  }

  void _showApiKeyDialog() {
    final keyInputController = TextEditingController(text: apiKey);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xff003b35),
          title: Text(
            "Gemini AI Key (Optional)",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your chatbot already answers questions reliably! If you also want Google Gemini 1.5 responses, you can enter your key below.",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: keyInputController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter AIzaSy... API Key (Optional)",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xff002521),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xffD4AF37)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xffD4AF37), width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffD4AF37),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {
                  apiKey = keyInputController.text.trim();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      apiKey.isEmpty ? "Saved successfully" : "Gemini API Key active!",
                    ),
                    backgroundColor: Colors.teal,
                  ),
                );
              },
              child: Text("Save", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          text:
              "As-salamu alaykum (السلام عليكم)! How may I assist your Islamic learning today?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfffe8f2f2),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
             Color(0xfffe8f2f2),
             Color(0xfffe8f2f2)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _messages.length <= 1
                    ? _buildEmptyStateWithSuggestions()
                    : _buildChatList(),
              ),
              if (_isLoading) _buildLoadingIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.teal, size: 20),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.teal,
            child: Icon(Icons.auto_awesome, color: Color(0xffD4AF37), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Islamic AI Assistant",
                  style: GoogleFonts.poppins(
                    color: Colors.teal,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Quran, Sunnah & Islamic Guidance",
                  style: GoogleFonts.poppins(
                    color: Colors.teal,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Settings / API Key",
            icon: Icon(
              apiKey.isEmpty ? Icons.vpn_key_outlined : Icons.vpn_key,
              color:  Colors.teal,
            ),
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            tooltip: "Clear Conversation",
            icon: const Icon(Icons.refresh, color: Colors.teal),
            onPressed: _clearChat,
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4, right: 8),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mosque, color: Colors.white, size: 18),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xff006d60) :  Colors.teal,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: Border.all(
                  color: isUser ? const Color(0xff009688) : Colors.teal,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: message.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Copied to clipboard"),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy, size: 13, color: Colors.white38),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4, left: 8),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xff006d60),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          _buildMessageBubble(_messages.first),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xffD4AF37), size: 18),
              const SizedBox(width: 8),
              Text(
                "Suggested Questions:",
                style: GoogleFonts.poppins(
                  color: const Color(0xffD4AF37),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._suggestedPrompts.map(
            (prompt) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: double.infinity,
              child: InkWell(
                onTap: () => _sendMessage(customPrompt: prompt),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xff002b26).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xff0a4b43)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          prompt,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xff002b26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xff0a4b43)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xffD4AF37)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Searching Quran & Sunnah...",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xff002521),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Color(0xfffe8f2f2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xff00584e)),
              ),
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(color: Colors.teal, fontSize: 14),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: "Ask any Islamic question...",
                  hintStyle: GoogleFonts.poppins(color: Colors.teal, fontSize: 13),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xffD4AF37),
            ),
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.black87, size: 20),
              onPressed: _isLoading ? null : () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}

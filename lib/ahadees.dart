import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:islamicapp/SavedSurahsScreen.dart';

class HadithBook {
  final String id;
  final String name;
  final String arabicName;
  final String writer;
  final int totalHadith;
  final String arabicUrl;
  final String urduUrl;
  final String englishUrl;

  const HadithBook({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.writer,
    required this.totalHadith,
    required this.arabicUrl,
    required this.urduUrl,
    required this.englishUrl,
  });
}

class HadithItem {
  final int hadithNumber;
  final String arabicText;
  final String urduTranslation;
  final String englishTranslation;
  final String? grade;

  HadithItem({
    required this.hadithNumber,
    required this.arabicText,
    required this.urduTranslation,
    required this.englishTranslation,
    this.grade,
  });
}

class AhadeesScreen extends StatefulWidget {
  const AhadeesScreen({super.key});

  @override
  State<AhadeesScreen> createState() => _AhadeesScreenState();
}

class _AhadeesScreenState extends State<AhadeesScreen> {
  // Active translation language: "urdu" or "english"
  String _selectedLanguage = "urdu";

  // Books list with verified API endpoints
  final List<HadithBook> _books = const [
    HadithBook(
      id: "bukhari",
      name: "Sahih al-Bukhari",
      arabicName: "صحيح البخاري",
      writer: "Imam Muhammad al-Bukhari",
      totalHadith: 7563,
      arabicUrl:
          "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-bukhari/sections/1.min.json",
      urduUrl:
          "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/urd-bukhari/sections/1.min.json",
      englishUrl:
          "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-bukhari/sections/1.min.json",
    ),
    HadithBook(
      id: "abudawud",
      name: "Sunan Abu Dawud",
      arabicName: "سنن أبي داود",
      writer: "Imam Abu Dawud",
      totalHadith: 5274,
      arabicUrl:
          "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-abudawud/sections/1.min.json",
      urduUrl:
          "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/urd-abudawud/sections/1.min.json",
      englishUrl:
          "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-abudawud/sections/1.min.json",
    ),
    HadithBook(
      id: "qudsi",
      name: "40 Hadith Qudsi",
      arabicName: "الأحاديث القدسية",
      writer: "Direct sayings of Allah through Prophet ﷺ",
      totalHadith: 40,
      arabicUrl:
          "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-qudsi.min.json",
      urduUrl:
          "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-qudsi.min.json",
      englishUrl:
          "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-qudsi.min.json",
    ),
  ];

  late HadithBook _selectedBook;
  List<HadithItem> _hadithList = [];
  List<HadithItem> _filteredList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Color Palette
  final Color _bgLightTeal = const Color(
    0xFFE8F2F2,
  ); // Soft mint/teal background
  final Color _primaryTeal = Colors.teal;
  final Color _mediumTeal = Colors.teal;
  final Color _goldAccent = const Color.fromARGB(
    255,
    243,
    243,
    243,
  ); // Islamic Gold

  @override
  void initState() {
    super.initState();
    _selectedBook = _books[0];
    _fetchHadiths(_selectedBook);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHadiths(HadithBook book) async {
    setState(() {
      _isLoading = true;
      _hadithList = [];
      _filteredList = [];
    });

    try {
      // 1. Fetch Arabic edition
      final resArabic = await http
          .get(Uri.parse(book.arabicUrl))
          .timeout(const Duration(seconds: 12));

      // 2. Fetch Urdu edition
      http.Response? resUrdu;
      if (book.urduUrl != book.arabicUrl) {
        try {
          resUrdu = await http
              .get(Uri.parse(book.urduUrl))
              .timeout(const Duration(seconds: 12));
        } catch (_) {}
      }

      // 3. Fetch English edition
      http.Response? resEng;
      try {
        resEng = await http
            .get(Uri.parse(book.englishUrl))
            .timeout(const Duration(seconds: 12));
      } catch (_) {}

      if (resArabic.statusCode == 200) {
        final dataArabic = jsonDecode(resArabic.body);
        final listArabic = dataArabic['hadiths'] as List;

        Map<int, String> urduMap = {};
        if (resUrdu != null && resUrdu.statusCode == 200) {
          final dataUrdu = jsonDecode(resUrdu.body);
          final listUrdu = dataUrdu['hadiths'] as List;
          for (var t in listUrdu) {
            final num = t['hadithnumber'] ?? t['arabicnumber'];
            if (num != null) {
              urduMap[num as int] = t['text'] ?? '';
            }
          }
        }

        Map<int, String> engMap = {};
        if (resEng != null && resEng.statusCode == 200) {
          final dataEng = jsonDecode(resEng.body);
          final listEng = dataEng['hadiths'] as List;
          for (var t in listEng) {
            final num = t['hadithnumber'] ?? t['arabicnumber'];
            if (num != null) {
              engMap[num as int] = t['text'] ?? '';
            }
          }
        }

        List<HadithItem> loaded = [];
        for (var item in listArabic) {
          final hNum =
              (item['hadithnumber'] ?? item['arabicnumber'] ?? 0) as int;
          final arabic = item['text'] ?? '';
          final urdu = urduMap[hNum] ?? '';
          final eng = engMap[hNum] ?? '';

          String? gradeStr;
          if (item['grades'] != null && (item['grades'] as List).isNotEmpty) {
            gradeStr = item['grades'][0]['grade'];
          }

          loaded.add(
            HadithItem(
              hadithNumber: hNum,
              arabicText: arabic,
              urduTranslation: urdu,
              englishTranslation: eng,
              grade: gradeStr ?? "Authentic / Sahih",
            ),
          );
        }

        if (mounted) {
          setState(() {
            _hadithList = loaded;
            _filteredList = loaded;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Server status code: ${resArabic.statusCode}");
      }
    } catch (e) {
      _loadFallbackHadiths();
    }
  }

  void _loadFallbackHadiths() {
    final offlineCollection = [
      HadithItem(
        hadithNumber: 1,
        arabicText:
            "إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى، فَمَنْ كَانَتْ هِجْرَتُهُ إِلَى دُنْيَا يُصِيبُهَا أَوْ إِلَى امْرَأَةٍ يَنْكِحُهَا، فَهِجْرَتُهُ إِلَى مَا هَاجَرَ إِلَيْهِ.",
        urduTranslation:
            "تمام اعمال کا دارومدار نیت پر ہے اور ہر انسان کے لیے وہی ہے جس کی اس نے نیت کی۔ (صحیح بخاری: 1)",
        englishTranslation:
            "The reward of deeds depends upon the intentions and every person will get the reward according to what he has intended. (Sahih al-Bukhari: 1)",
        grade: "Sahih Bukhari",
      ),
      HadithItem(
        hadithNumber: 2,
        arabicText:
            "الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ.",
        urduTranslation:
            "مسلمان وہ ہے جس کی زبان اور ہاتھ کی تکلیف سے دوسرے مسلمان محفوظ رہیں۔ (صحیح بخاری: 10)",
        englishTranslation:
            "A Muslim is the one from whose tongue and hands other Muslims are safe. (Sahih al-Bukhari: 10)",
        grade: "Sahih Bukhari",
      ),
      HadithItem(
        hadithNumber: 3,
        arabicText:
            "لاَ يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ.",
        urduTranslation:
            "تم میں سے کوئی اس وقت تک کامل مومن نہیں ہو سکتا جب تک وہ اپنے بھائی کے لیے وہی پسند نہ کرے جو اپنے لیے کرتا ہے۔ (صحیح بخاری: 13)",
        englishTranslation:
            "None of you truly believes until he loves for his brother what he loves for himself. (Sahih al-Bukhari: 13)",
        grade: "Sahih Bukhari",
      ),
      HadithItem(
        hadithNumber: 4,
        arabicText: "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ.",
        urduTranslation:
            "تم میں سب سے بہترین شخص وہ ہے جو قرآن سیکھے اور دوسروں کو سکھائے۔ (صحیح بخاری: 5027)",
        englishTranslation:
            "The best among you are those who learn the Quran and teach it. (Sahih al-Bukhari: 5027)",
        grade: "Sahih Bukhari",
      ),
      HadithItem(
        hadithNumber: 5,
        arabicText:
            "كَلِمَتَانِ حَبِيبَتَانِ إِلَى الرَّحْمَنِ، خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي الْمِيزَانِ: سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ.",
        urduTranslation:
            "دو کلمے جو زبان پر ہلکے، میزان میں وزنی اور رحمٰن کو بہت پیارے ہیں: سبحان اللہ وبحمدہ، سبحان اللہ العظیم۔ (صحیح مسلم)",
        englishTranslation:
            "Two words are light on the tongue, heavy on the balance, and beloved to the Most Merciful: 'Subhan Allahi wa bihamdihi, Subhan Allahil Azeem'. (Sahih Muslim)",
        grade: "Sahih Muslim",
      ),
      HadithItem(
        hadithNumber: 6,
        arabicText: "الطُّهُورُ شَطْرُ الإِيمَانِ.",
        urduTranslation: "پاکیزگی اور صفائی آدھا ایمان ہے۔ (صحیح مسلم: 223)",
        englishTranslation:
            "Cleanliness and purity is half of faith. (Sahih Muslim: 223)",
        grade: "Sahih Muslim",
      ),
      HadithItem(
        hadithNumber: 7,
        arabicText:
            "الرَّاحِمُونَ يَرْحَمُهُمُ الرَّحْمَنُ، ارْحَمُوا مَنْ فِي الأَرْضِ يَرْحَمْكُمْ مَنْ فِي السَّمَاءِ.",
        urduTranslation:
            "رحم کرنے والوں پر رحمٰن رحم فرماتا ہے۔ تم زمین والوں پر رحم کرو، آسمان والا تم پر رحم کرے گا۔ (سنن الترمذی: 1924)",
        englishTranslation:
            "The merciful will be shown mercy by the Most Merciful. Be merciful to those on the earth, and the One in the heavens will have mercy on you. (Jami At-Tirmidhi: 1924)",
        grade: "Hasan Sahih",
      ),
    ];

    if (mounted) {
      setState(() {
        _hadithList = offlineCollection;
        _filteredList = offlineCollection;
        _isLoading = false;
      });
    }
  }

  void _filterHadiths(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredList = _hadithList;
      });
      return;
    }

    final lower = query.toLowerCase();
    setState(() {
      _filteredList = _hadithList.where((h) {
        return h.arabicText.contains(query) ||
            h.urduTranslation.contains(query) ||
            h.englishTranslation.toLowerCase().contains(lower) ||
            h.hadithNumber.toString().contains(lower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLightTeal,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildBookSelector(),
            _buildLanguageSelector(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _filteredList.isEmpty
                  ? _buildEmpty()
                  : _buildHadithList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            child: Icon(Icons.menu_book_rounded, color: _goldAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hadith Collection",
                  style: GoogleFonts.poppins(
                    color: _primaryTeal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  "الأحاديث النبوية الشريفة",
                  style: GoogleFonts.amiri(
                    color: _mediumTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: _primaryTeal),
            onPressed: () => _fetchHadiths(_selectedBook),
          ),
        ],
      ),
    );
  }

  Widget _buildBookSelector() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          final isSelected = book.id == _selectedBook.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                if (_selectedBook.id != book.id) {
                  setState(() {
                    _selectedBook = book;
                  });
                  _fetchHadiths(book);
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryTeal : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? _primaryTeal : Colors.teal.shade200,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    book.name,
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : _primaryTeal,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedLanguage = "urdu";
                  });
                },
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: _selectedLanguage == "urdu"
                        ? _primaryTeal
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.translate,
                        size: 15,
                        color: _selectedLanguage == "urdu"
                            ? Colors.white
                            : _primaryTeal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "اردو ترجمہ (Urdu)",
                        style: GoogleFonts.notoNastaliqUrdu(
                          color: _selectedLanguage == "urdu"
                              ? Colors.white
                              : _primaryTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedLanguage = "english";
                  });
                },
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: _selectedLanguage == "english"
                        ? _primaryTeal
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.language,
                        size: 15,
                        color: _selectedLanguage == "english"
                            ? Colors.white
                            : _primaryTeal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "English Translation",
                        style: GoogleFonts.poppins(
                          color: _selectedLanguage == "english"
                              ? Colors.white
                              : _primaryTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
          onChanged: _filterHadiths,
          style: GoogleFonts.poppins(color: _primaryTeal, fontSize: 13),
          decoration: InputDecoration(
            hintText: _selectedLanguage == "urdu"
                ? "حدیث نمبر یا کسی بھی لفظ سے تلاش کریں..."
                : "Search hadith by keyword or number...",
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
                      _filterHadiths("");
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

  Future<void> _bookmarkHadith(HadithItem hadith, String translation) async {
    await SavedStorage.saveItem({
      'id': 'hadith-${_selectedBook.id}:${hadith.hadithNumber}',
      'category': 'Hadith',
      'arabic': hadith.arabicText,
      'translation': translation,
      'reference': '${_selectedBook.name} • Hadith ${hadith.hadithNumber}',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bookmark added')));
  }

  Widget _buildHadithList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) {
        final hadith = _filteredList[index];
        return _buildHadithCard(hadith);
      },
    );
  }

  Widget _buildHadithCard(HadithItem hadith) {
    final hasUrdu = hadith.urduTranslation.trim().isNotEmpty;
    final hasEnglish = hadith.englishTranslation.trim().isNotEmpty;

    // Pick active translation or fallback to whichever is available
    final isUrdu = _selectedLanguage == "urdu"
        ? (hasUrdu || !hasEnglish)
        : !hasEnglish;
    final activeTranslation = isUrdu
        ? (hasUrdu ? hadith.urduTranslation : hadith.englishTranslation)
        : (hasEnglish ? hadith.englishTranslation : hadith.urduTranslation);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade900.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _primaryTeal,
                border: Border(
                  bottom: BorderSide(
                    color: _goldAccent.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _goldAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Hadith #${hadith.hadithNumber}",
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (hadith.grade != null && hadith.grade!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _goldAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        hadith.grade!,
                        style: GoogleFonts.poppins(
                          color: _goldAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  InkWell(
                    onTap: () {
                      final copyText =
                          "${hadith.arabicText}\n\n$activeTranslation\n(${_selectedBook.name} - #${hadith.hadithNumber})";
                      Clipboard.setData(ClipboardData(text: copyText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Hadith copied to clipboard!",
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: _primaryTeal,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.copy_rounded,
                      color: _goldAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: "Bookmark Hadith",
                    child: InkWell(
                      onTap: () => _bookmarkHadith(hadith, activeTranslation),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.bookmark_border_rounded,
                          color: _goldAccent,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Arabic Text
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SelectableText(
                  hadith.arabicText,
                  style: GoogleFonts.amiri(
                    color: _primaryTeal,
                    fontSize: 20,
                    height: 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),

            // Divider with icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.teal.shade200, thickness: 0.7),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.star, color: _goldAccent, size: 12),
                  ),
                  Expanded(
                    child: Divider(color: Colors.teal.shade200, thickness: 0.7),
                  ),
                ],
              ),
            ),

            // Translation (Urdu or English)
            if (activeTranslation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Directionality(
                  textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  child: SelectableText(
                    activeTranslation,
                    style: isUrdu
                        ? GoogleFonts.notoNastaliqUrdu(
                            color: Colors.grey.shade900,
                            fontSize: 14,
                            height: 2.1,
                          )
                        : GoogleFonts.poppins(
                            color: Colors.grey.shade800,
                            fontSize: 13,
                            height: 1.5,
                          ),
                    textAlign: isUrdu ? TextAlign.justify : TextAlign.left,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryTeal),
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 14),
          Text(
            "Loading Hadiths from API...",
            style: GoogleFonts.poppins(
              color: _primaryTeal,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
            "No Hadith found matching your search",
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

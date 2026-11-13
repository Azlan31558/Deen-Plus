import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedStorage {
  static const String key = 'saved_items';

  // Save item
  static Future<void> saveItem(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> savedList = prefs.getStringList(key) ?? [];

    // Prevent duplicate bookmarks
    bool alreadySaved = savedList.any((element) {
      final data = jsonDecode(element);
      return data['id'].toString() == item['id'].toString();
    });

    if (!alreadySaved) {
      savedList.add(jsonEncode(item));
      await prefs.setStringList(key, savedList);
    }
  }

  // Get all saved items
  static Future<List<Map<String, dynamic>>> getItems() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> savedList = prefs.getStringList(key) ?? [];

    return savedList.map((item) {
      return Map<String, dynamic>.from(jsonDecode(item));
    }).toList();
  }

  // Remove bookmark
  static Future<void> removeItem(String id) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> savedList = prefs.getStringList(key) ?? [];

    savedList.removeWhere((element) {
      final data = jsonDecode(element);
      return data['id'].toString() == id;
    });

    await prefs.setStringList(key, savedList);
  }
}

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Map<String, dynamic>> savedItems = [];
  bool isLoading = true;
  String selectedCategory = 'All';

  final Color bgColor = const Color(0xFFE8F3F3);
  final Color primaryColor = const Color(0xFF009688);

  @override
  void initState() {
    super.initState();
    loadSavedItems();
  }

  Future<void> loadSavedItems() async {
    final data = await SavedStorage.getItems();

    if (!mounted) return;

    setState(() {
      savedItems = data;
      isLoading = false;
    });
  }

  Future<void> deleteItem(String id) async {
    await SavedStorage.removeItem(id);
    await loadSavedItems();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark removed successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> get filteredItems {
    if (selectedCategory == 'All') {
      return savedItems;
    }

    return savedItems.where((item) {
      return item['category'] == selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new, color: primaryColor),
                  ),

                  Container(
                    height: 65,
                    width: 65,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bookmark,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved Collection',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'محفوظ آیات، احادیث اور دعائیں',
                          style: TextStyle(fontSize: 15, color: primaryColor),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      loadSavedItems();
                    },
                    icon: Icon(Icons.refresh, color: primaryColor, size: 30),
                  ),
                ],
              ),
            ),

            // CATEGORY FILTER
            SizedBox(
              height: 55,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  categoryButton('All'),
                  categoryButton('Ayah'),
                  categoryButton('Hadith'),
                  categoryButton('Dua'),
                  categoryButton('Azkar'),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // SAVED ITEMS COUNT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  Text(
                    'Your Bookmarks',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${filteredItems.length} Items',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // SAVED LIST
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : filteredItems.isEmpty
                  ? emptyScreen()
                  : RefreshIndicator(
                      color: primaryColor,
                      onRefresh: loadSavedItems,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];

                          return savedCard(item);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // CATEGORY BUTTON
  Widget categoryButton(String title) {
    bool isSelected = selectedCategory == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: primaryColor.withOpacity(0.4), width: 1.5),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // SAVED ITEM CARD
  Widget savedCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(21),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['category'] ?? 'Saved',
                    style: const TextStyle(
                      color: Color(0xFF009688),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Flexible(
                  child: Text(
                    item['reference'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    deleteItem(item['id'].toString());
                  },
                  icon: const Icon(Icons.bookmark, color: Colors.white),
                ),
              ],
            ),
          ),

          // ARABIC TEXT
          if ((item['arabic'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  item['arabic'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    height: 2,
                    color: Color(0xFF008F83),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // DIVIDER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Divider(color: primaryColor.withOpacity(0.3), thickness: 1),
          ),

          // TRANSLATION
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            child: Text(
              item['translation'] ?? '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 17,
                height: 1.9,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // EMPTY SCREEN
  Widget emptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 85,
            color: primaryColor.withOpacity(0.4),
          ),

          const SizedBox(height: 15),

          Text(
            'No Saved Items Yet',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Your bookmarked Ayat, Hadith, Dua and Azkar\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6),
          ),
        ],
      ),
    );
  }
}

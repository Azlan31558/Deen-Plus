import 'package:flutter/material.dart';
import 'package:islamicapp/language_provider.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String selectedLanguage;
  final _languageProvider = LanguageProvider();

  final List<Map<String, dynamic>> languages = [
    {'name': 'English', 'code': 'en', 'flag': '🇬🇧'},
    {'name': 'اردو', 'code': 'ur', 'flag': '🇵🇰'},
    {'name': 'العربية', 'code': 'ar', 'flag': '🇸🇦'},
    {'name': 'Français', 'code': 'fr', 'flag': '🇫🇷'},
    {'name': 'Español', 'code': 'es', 'flag': '🇪🇸'},
    {'name': 'Deutsch', 'code': 'de', 'flag': '🇩🇪'},
  ];

  @override
  void initState() {
    super.initState();
    selectedLanguage = _languageProvider.currentLanguage;
    _languageProvider.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        selectedLanguage = _languageProvider.currentLanguage;
      });
    }
  }

  @override
  void dispose() {
    _languageProvider.removeListener(_onLanguageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xffF5FAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppTranslations.translate('select_language', selectedLanguage),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView.builder(
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final language = languages[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  border: Border.all(
                    color: selectedLanguage == language['code']
                        ? const Color(0xFF118785)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    _languageProvider.setLanguage(language['code']);
                  },
                  leading: Text(
                    language['flag'],
                    style: const TextStyle(fontSize: 30),
                  ),
                  title: Text(
                    language['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: selectedLanguage == language['code']
                          ? const Color(0xFF118785)
                          : Colors.black,
                    ),
                  ),
                  trailing: selectedLanguage == language['code']
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF118785),
                          size: 28,
                        )
                      : const Icon(
                          Icons.circle_outlined,
                          color: Colors.grey,
                          size: 28,
                        ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language changed to ${languages.firstWhere((l) => l['code'] == selectedLanguage)['name']}'),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        },
        backgroundColor: const Color(0xFF118785),
        child: const Icon(Icons.check),
      ),
    );
  }
}

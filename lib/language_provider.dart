import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
  }
}

class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'setting': 'Setting',
      'preferences': 'Preferences',
      'language': 'Language',
      'privacy_policy': 'Privacy Policy',
      'share_app': 'Share App',
      'rate_us': 'Rate us',
      'more_apps': 'More Apps',
      'logout': 'Logout',
      'confirm_logout': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'select_language': 'Select Language',
    },
    'ur': {
      'setting': 'ترتیبات',
      'preferences': 'ترجیحات',
      'language': 'زبان',
      'privacy_policy': 'رازداری کی پالیسی',
      'share_app': 'ایپ شیئر کریں',
      'rate_us': 'ہمیں ریٹ کریں',
      'more_apps': 'مزید ایپس',
      'logout': 'لاگ آؤٹ',
      'confirm_logout': 'کیا آپ یقینی ہیں کہ آپ لاگ آؤٹ کرنا چاہتے ہیں؟',
      'cancel': 'منسوخ کریں',
      'select_language': 'زبان منتخب کریں',
    },
    'ar': {
      'setting': 'الإعدادات',
      'preferences': 'التفضيلات',
      'language': 'اللغة',
      'privacy_policy': 'سياسة الخصوصية',
      'share_app': 'مشاركة التطبيق',
      'rate_us': 'قيمنا',
      'more_apps': 'المزيد من التطبيقات',
      'logout': 'تسجيل الخروج',
      'confirm_logout': 'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
      'cancel': 'إلغاء',
      'select_language': 'اختر اللغة',
    },
    'fr': {
      'setting': 'Paramètres',
      'preferences': 'Préférences',
      'language': 'Langue',
      'privacy_policy': 'Politique de confidentialité',
      'share_app': 'Partager l\'application',
      'rate_us': 'Évaluez-nous',
      'more_apps': 'Plus d\'applications',
      'logout': 'Déconnexion',
      'confirm_logout': 'Êtes-vous sûr de vouloir vous déconnecter?',
      'cancel': 'Annuler',
      'select_language': 'Sélectionner la langue',
    },
    'es': {
      'setting': 'Configuración',
      'preferences': 'Preferencias',
      'language': 'Idioma',
      'privacy_policy': 'Política de privacidad',
      'share_app': 'Compartir aplicación',
      'rate_us': 'Califícanos',
      'more_apps': 'Más aplicaciones',
      'logout': 'Cerrar sesión',
      'confirm_logout': '¿Estás seguro de que deseas cerrar sesión?',
      'cancel': 'Cancelar',
      'select_language': 'Seleccionar idioma',
    },
    'de': {
      'setting': 'Einstellungen',
      'preferences': 'Einstellungen',
      'language': 'Sprache',
      'privacy_policy': 'Datenschutzrichtlinie',
      'share_app': 'App teilen',
      'rate_us': 'Bewerten Sie uns',
      'more_apps': 'Weitere Apps',
      'logout': 'Abmelden',
      'confirm_logout': 'Sind Sie sicher, dass Sie sich abmelden möchten?',
      'cancel': 'Abbrechen',
      'select_language': 'Sprache wählen',
    },
  };

  static String translate(String key, String languageCode) {
    return translations[languageCode]?[key] ?? translations['en']?[key] ?? key;
  }
}

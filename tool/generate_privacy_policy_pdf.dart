import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Widget _sectionTitle(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14, bottom: 5),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.teal800,
      ),
    ),
  );
}

pw.Widget _paragraph(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 7),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
    ),
  );
}

Future<void> main() async {
  final document = pw.Document(
    title: 'Deen Plus Privacy Policy',
    author: 'Deen Plus',
  );

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 52),
      header: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'DEEN PLUS',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal700,
          ),
        ),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.center,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ),
      build: (context) => [
        pw.SizedBox(height: 12),
        pw.Text(
          'Privacy Policy',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Effective date: November 13, 2026',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        _paragraph(
          'This policy explains how the Deen Plus mobile application handles information. It describes the app functionality present as of the effective date and should be updated if the app or its service providers change.',
        ),
        _sectionTitle('Information stored on your device'),
        _paragraph(
          'The app does not require an account. When you bookmark Quran verses, Hadith, or Azkar, those saved items are stored locally on your device using the platform preferences store. They remain until you remove them, clear the app data, or uninstall the app. Chat messages and an optional Gemini API key are held in memory while the relevant screen is open and are not saved to persistent storage by the current app code.',
        ),
        _sectionTitle('Location'),
        _paragraph(
          'The Qibla feature may request precise device location after you open it and grant permission. The current Qibla feature uses the coordinates on your device to calculate the Qibla direction and distance; it does not send those coordinates to the app developer. Prayer-time requests use the configured city of Sahiwal and the date, rather than your GPS coordinates.',
        ),
        _sectionTitle('Online content and searches'),
        _paragraph(
          'The app connects to third-party services to retrieve Quran text and translations, Hadith, Azkar, prayer times, and audio. These requests may disclose standard network information, such as your IP address, to the relevant service provider. Quran searches in the Islamic AI feature may send a selected search term to Quran.com. Each provider handles information under its own privacy policy.',
        ),
        _sectionTitle('Optional Google Gemini feature'),
        _paragraph(
          'If you enter your own Gemini API key and use the Islamic AI feature, the app sends your prompt and API key to Google Gemini over HTTPS to request a response. Google processes that information under Google terms and privacy policies. Do not enter sensitive personal information in prompts. The app keeps the key only in screen memory for the current session.',
        ),
        _sectionTitle('Sharing and ratings'),
        _paragraph(
          'If you use Share App, the operating system displays available sharing options. Information is sent only to the destination you choose. Rate Us opens the app store listing when one is available; store interactions and reviews are handled by Google Play.',
        ),
        _sectionTitle('Advertising and analytics'),
        _paragraph(
          'The current app code does not include an advertising or analytics SDK. This statement may change if such services are added in a future version, in which case this policy will be updated.',
        ),
        _sectionTitle('Retention, security, and your choices'),
        _paragraph(
          'You can remove individual bookmarks from the Saved screen. You can also revoke location permission in your device settings. Third-party providers may retain information they receive according to their own policies. The app uses network connections to its services, but no method of storage or transmission is completely secure.',
        ),
        _sectionTitle('Children'),
        _paragraph(
          'Deen Plus is a general religious information app and is not designed to collect personal information from children. If you believe a child has provided personal information to a third-party service through the app, contact that service directly.',
        ),
        _sectionTitle('Changes to this policy'),
        _paragraph(
          'This policy may be updated when app features, data handling, or service providers change. The latest version should be included with the app and its effective date will be updated.',
        ),
        _sectionTitle('Contact'),
        _paragraph(
          'For privacy questions or requests, contact the developer at raoazlan2@gmail.com.',
        ),
      ],
    ),
  );

  final output = File('assets/privacy_policy.pdf');
  await output.parent.create(recursive: true);
  await output.writeAsBytes(await document.save());
  stdout.writeln('Created ${output.path}');
}

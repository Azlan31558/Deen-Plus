import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islamicapp/dashboard.dart';
import 'package:islamicapp/language_screen.dart';
import 'package:islamicapp/language_provider.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  late LanguageProvider _languageProvider;

  @override
  void initState() {
    super.initState();
    _languageProvider = LanguageProvider();
    _languageProvider.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _languageProvider.removeListener(_onLanguageChanged);
    super.dispose();
  }

  String _translate(String key) {
    return AppTranslations.translate(key, _languageProvider.currentLanguage);
  }

  Future<void> _shareApp() async {
    try {
      final result = await SharePlus.instance.share(
        const ShareParams(
          subject: 'Deen Plus',
          text:
              'Explore Deen Plus for Quran, Hadith, prayer times, and Azkar.\n'
              'Get it on Google Play:\n'
              'https://play.google.com/store/apps/details?id=com.example.islamicapp',
        ),
      );

      if (!mounted || result.status != ShareResultStatus.unavailable) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing is unavailable on this device.')),
      );
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share the app right now.')),
      );
    }
  }

  Future<void> _rateApp() async {
    try {
      await InAppReview.instance.openStoreListing();
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The Play Store listing will be available after the app is published.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5FAFA),

      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            SizedBox(height: 45),
            Padding(
              padding: const EdgeInsets.only(left: 22.0, right: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translate('setting'),
                        style: TextStyle(
                          fontSize: 38,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        height: 6,
                        width: 68,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [Colors.teal, Colors.white],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 22.0),
                    child: Container(
                      height: 45,
                      width: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Color(0xfffe8f5f4),
                        border: Border.all(
                          color: Color.fromARGB(255, 160, 192, 189),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          Icon(
                            Icons.location_pin,
                            color: Color.fromARGB(255, 5, 63, 61),
                          ),
                          Text(
                            'Sahiwal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xfff7e8a93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Divider(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 22.0, right: 22, top: 16),
              child: Row(
                spacing: 10,
                children: [
                  Container(
                    height: 30,
                    width: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Color(0xFff118785),
                    ),
                  ),
                  Text(
                    _translate('preferences'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LanguageScreen(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: Row(
                                spacing: 15,
                                children: [
                                  Container(
                                    height: 45,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: const Color.fromARGB(
                                        117,
                                        182,
                                        158,
                                        187,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.language,
                                      color: const Color.fromARGB(
                                        255,
                                        119,
                                        47,
                                        126,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _translate('language'),
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 2),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 15,
                              children: [
                                Container(
                                  height: 45,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: const Color.fromARGB(
                                      57,
                                      71,
                                      123,
                                      165,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.security,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  _translate('privacy_policy'),
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 2),
                    InkWell(
                      onTap: _shareApp,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 15,
                              children: [
                                Container(
                                  height: 45,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: const Color.fromARGB(
                                      76,
                                      160,
                                      37,
                                      123,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.ios_share_sharp,
                                    color: Color.fromARGB(255, 173, 22, 93),
                                  ),
                                ),
                                Text(
                                  _translate('share_app'),
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 2),
                    InkWell(
                      onTap: _rateApp,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 15,
                              children: [
                                Container(
                                  height: 45,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: const Color.fromARGB(
                                      117,
                                      182,
                                      158,
                                      187,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.star_rate_outlined,
                                    color: Color.fromARGB(255, 163, 177, 37),
                                  ),
                                ),
                                Text(
                                  _translate('rate_us'),
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 2),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Row(
                              spacing: 15,
                              children: [
                                Container(
                                  height: 45,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: const Color.fromARGB(
                                      117,
                                      182,
                                      158,
                                      187,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.app_registration_sharp,
                                    color: const Color.fromARGB(
                                      255,
                                      119,
                                      47,
                                      126,
                                    ),
                                  ),
                                ),
                                Text(
                                  _translate('more_apps'),
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 2),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(_translate('logout')),
                                content: Text(_translate('are_you_sure_you_want_to_logout')),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // Navigate to surah screen
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SplashScreen2(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: Row(
                                spacing: 15,
                                children: [
                                  Container(
                                    height: 45,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: const Color.fromARGB(
                                        117,
                                        255,
                                        193,
                                        7,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.logout,
                                      color: const Color.fromARGB(
                                        255,
                                        255,
                                        111,
                                        0,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Text('Recount'),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     AnimatedNumber(
            //         startValue: 200,
            //         endValue: 500,
            //         duration: Duration(seconds: 12),
            //         isFloatingPoint: false,
            //         style: TextStyle(
            //         color: Colors.orange,
            //         fontSize: 35,fontWeight: FontWeight.bold
            //         ),
            //     ),Text('+',style: TextStyle(fontSize: 35,fontWeight: FontWeight.bold,color: Colors.orange),),
            //   ],
            // ),
             
        

          ],
        ),
      ),
    );
  }
}

// class PrivacyPolicyScreen extends StatefulWidget {
//   const PrivacyPolicyScreen({super.key});

//   @override
//   State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
// }

// class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
//   late final PdfControllerPinch _pdfController;

//   @override
//   void initState() {
//     super.initState();
//     _pdfController = PdfControllerPinch(
//       document: PdfDocument.openAsset('assets/privacy_policy.pdf'),
//     );
//   }

//   @override
//   void dispose() {
//     _pdfController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Privacy Policy'),
//         backgroundColor: Colors.teal,
//         foregroundColor: Colors.white,
//       ),
//       body: PdfViewPinch(controller: _pdfController),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:islamicapp/navbar.dart';

class SplashScreen2 extends StatefulWidget {
  const SplashScreen2({super.key});

  @override
  State<SplashScreen2> createState() => _SplashScreen2State();
}

class _SplashScreen2State extends State<SplashScreen2> {
     
     @override
 void initState() {
    super.initState();

    _navigateToName();
  }
  
  void _navigateToName() async {
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Navbar()),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(    
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash_img.png',fit: BoxFit.cover,),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Deen',style: TextStyle(color: Colors.white,fontSize: 52,fontWeight: FontWeight.w900,letterSpacing: 1,shadows:[Shadow(blurRadius: 25,color: Colors.black38)]),),
                    SizedBox(width: 8,),
                    Text('Plus',style: TextStyle(fontSize: 52,fontWeight: FontWeight.w900,color: Color(0xffFFD86A),),),
                  ],
                ),
                SizedBox(height: 18,),
                Container(
                  height: 4,
                  width: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(colors: [
                      Color(0xff18D2D1),
                            Color(0xff0F9A94),
                    ])
                  ),
                ),
                SizedBox(height: 19,),
                Text('Your Companion in Faith',style: TextStyle(fontSize: 19,color: Colors.white70,fontWeight: FontWeight.w500,letterSpacing: .8),)
              ],
            ),
          )
        ],
      ),
    );
  }
}
 
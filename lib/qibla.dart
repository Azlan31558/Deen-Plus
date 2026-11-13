
import 'dart:async';
import 'dart:math' as math;
 
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {

  // Kaaba Location
  final double kaabaLat = 21.4225;
  final double kaabaLng = 39.8262;

  double? currentLat;
  double? currentLng;

  double? qiblaDirection;
  double? compassHeading;

  double? distance;

  bool isLoading = true;
  String errorMessage = '';

  StreamSubscription<CompassEvent>? compassSubscription;

  @override
  void initState() {
    super.initState();

    getLocation();

    compassSubscription =
        FlutterCompass.events?.listen((event) {

      if (event.heading != null) {

        if (mounted) {
          setState(() {
            compassHeading = event.heading!;
          });
        }

      }

    });
  }

  // Get Current Location
  Future<void> getLocation() async {

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {

      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Please enable GPS location');
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {

        permission = await Geolocator.requestPermission();

      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Enable it from settings.',
        );
      }

      Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      double lat = position.latitude;
      double lng = position.longitude;

      double bearing = calculateQibla(lat, lng);

      double meters = Geolocator.distanceBetween(
        lat,
        lng,
        kaabaLat,
        kaabaLng,
      );

      if (mounted) {

        setState(() {

          currentLat = lat;
          currentLng = lng;

          qiblaDirection = bearing;
          distance = meters / 1000;

          isLoading = false;

        });

      }

    } catch (e) {

      if (mounted) {

        setState(() {

          errorMessage = e.toString().replaceFirst(
            'Exception: ',
            '',
          );

          isLoading = false;

        });

      }

    }

  }

  // Calculate Qibla Bearing
  double calculateQibla(double lat, double lng) {

    double lat1 = lat * math.pi / 180;
    double lat2 = kaabaLat * math.pi / 180;

    double difference =
        (kaabaLng - lng) * math.pi / 180;

    double y = math.sin(difference);

    double x =
        math.cos(lat1) * math.tan(lat2) -
        math.sin(lat1) * math.cos(difference);

    double bearing = math.atan2(y, x);

    return (bearing * 180 / math.pi + 360) % 360;

  }

  @override
  void dispose() {

    compassSubscription?.cancel();

    super.dispose();

  }

  @override
  Widget build(BuildContext context) {

    double relativeAngle = 0;

    if (qiblaDirection != null && compassHeading != null) {

      relativeAngle =
          (qiblaDirection! - compassHeading! + 360) % 360;

    }

    return Scaffold(

      backgroundColor: const Color(0xfff2f8f7),

      appBar: AppBar(

        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Qibla Direction',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [

          IconButton(
            onPressed: getLocation,
            icon: const Icon(Icons.refresh),
          ),

        ],

      ),

      body: isLoading

          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.teal,
              ),
            )

          : errorMessage.isNotEmpty

              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(25),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        const Icon(
                          Icons.location_off,
                          color: Colors.teal,
                          size: 65,
                        ),

                        const SizedBox(height: 15),

                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: getLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Try Again'),
                        ),

                      ],
                    ),
                  ),
                )

              : SingleChildScrollView(

                  padding: const EdgeInsets.all(18),

                  child: Column(

                    children: [

                      // Header
                      Container(

                        width: double.infinity,
                        padding: const EdgeInsets.all(20),

                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(22),
                        ),

                        child: const Column(
                          children: [

                            Icon(
                              Icons.mosque,
                              color: Colors.white,
                              size: 45,
                            ),

                            SizedBox(height: 10),

                            Text(
                              'Find Your Qibla',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              'Face the direction of Holy Kaaba',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),

                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Qibla Direction Card
                      Container(

                        width: double.infinity,
                        padding: const EdgeInsets.all(20),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),

                        child: Column(
                          children: [

                            const Text(
                              'QIBLA COMPASS',
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),

                            const SizedBox(height: 25),

                            // Compass
                            SizedBox(
                              height: 290,
                              width: 290,

                              child: Stack(
                                alignment: Alignment.center,

                                children: [

                                  // Outer Circle
                                  Container(
                                    height: 280,
                                    width: 280,

                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,

                                      color: const Color(0xffe5f5f2),

                                      border: Border.all(
                                        color: Colors.teal,
                                        width: 3,
                                      ),
                                    ),
                                  ),

                                  // Inner Circle
                                  Container(
                                    height: 230,
                                    width: 230,

                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,

                                      border: Border.all(
                                        color: Colors.teal.withOpacity(0.2),
                                        width: 2,
                                      ),
                                    ),
                                  ),

                                  // Cardinal Directions
                                  const Positioned(
                                    top: 13,
                                    child: Text(
                                      'N',
                                      style: TextStyle(
                                        color: Colors.teal,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 19,
                                      ),
                                    ),
                                  ),

                                  const Positioned(
                                    bottom: 13,
                                    child: Text(
                                      'S',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 19,
                                      ),
                                    ),
                                  ),

                                  const Positioned(
                                    left: 13,
                                    child: Text(
                                      'W',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 19,
                                      ),
                                    ),
                                  ),

                                  const Positioned(
                                    right: 13,
                                    child: Text(
                                      'E',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 19,
                                      ),
                                    ),
                                  ),

                                  // Qibla Arrow
                                  if (compassHeading != null)

                                    Transform.rotate(

                                      angle: relativeAngle *
                                          math.pi / 180,

                                      child: const Icon(
                                        Icons.navigation,
                                        size: 105,
                                        color: Color(0xff008577),
                                      ),

                                    )

                                  else

                                    const Icon(
                                      Icons.explore,
                                      size: 90,
                                      color: Colors.teal,
                                    ),

                                  // Center
                                  Container(
                                    height: 18,
                                    width: 18,

                                    decoration: const BoxDecoration(
                                      color: Color(0xffd6ad48),
                                      shape: BoxShape.circle,
                                    ),
                                  ),

                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Qibla Bearing
                            Text(
                              '${qiblaDirection!.toStringAsFixed(1)}°',
                              style: const TextStyle(
                                fontSize: 35,
                                color: Color(0xff008577),
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const Text(
                              'Qibla Bearing from North',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 12),

                            if (compassHeading == null)

                              const Text(
                                'Compass sensor unavailable',
                                style: TextStyle(
                                  color: Colors.orange,
                                ),
                              )

                            else

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 9,
                                ),

                                decoration: BoxDecoration(
                                  color: const Color(0xffe1f4ef),
                                  borderRadius: BorderRadius.circular(20),
                                ),

                                child: const Text(
                                  'Rotate your phone to align the arrow',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Location Information
                      Container(

                        padding: const EdgeInsets.all(18),
                        width: double.infinity,

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            const Row(
                              children: [

                                Icon(
                                  Icons.location_on,
                                  color: Colors.teal,
                                ),

                                SizedBox(width: 8),

                                Text(
                                  'Your Location',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                              ],
                            ),

                            const SizedBox(height: 18),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [

                                const Text(
                                  'Latitude',
                                  style: TextStyle(color: Colors.grey),
                                ),

                                Text(
                                  currentLat!.toStringAsFixed(5),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [

                                const Text(
                                  'Longitude',
                                  style: TextStyle(color: Colors.grey),
                                ),

                                Text(
                                  currentLng!.toStringAsFixed(5),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                              ],
                            ),

                            const Divider(height: 25),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [

                                const Text(
                                  'Distance to Kaaba',
                                  style: TextStyle(color: Colors.grey),
                                ),

                                Text(
                                  '${distance!.toStringAsFixed(1)} KM',
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                              ],
                            ),

                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Important Note
                      Container(
                        padding: const EdgeInsets.all(15),

                        decoration: BoxDecoration(
                          color: const Color(0xffe3f4ef),
                          borderRadius: BorderRadius.circular(18),
                        ),

                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Icon(
                              Icons.info_outline,
                              color: Colors.teal,
                            ),

                            SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                'Keep your phone flat and away from metal objects. Calibrate your compass if the direction appears inaccurate.',
                                style: TextStyle(
                                  color: Color(0xff356b62),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),

                    ],
                  ),
                ),
    );
  }
}

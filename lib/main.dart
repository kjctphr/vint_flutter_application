import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'start_screen.dart';

void main() {
  if (WebRTC.platformIsDesktop) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  } else if (WebRTC.platformIsAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Marker Based Indoor Navigation App',
        theme: ThemeData(primarySwatch: Colors.blue),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(
            title: Text('Indoor Navigation App'),
          ),
          body: Container(
            decoration: BoxDecoration(gradient: LinearGradient(
                colors: const [
                  Color.fromARGB(255, 78, 13, 255),
                  Color.fromARGB(255, 107, 15, 222),
                ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )),
            child: const StartScreen(),
          ),
        )
    );
  }
}
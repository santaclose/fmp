import 'package:audio_service/audio_service.dart';
import 'package:fmp/artists.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fmp',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: AudioServiceWidget(child: ArtistsPage()),
    );
  }
}

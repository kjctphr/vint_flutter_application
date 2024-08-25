import 'package:flutter/material.dart';
import 'create_topomap.dart';
import 'navigate.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateTopomap()),
                );
              },
              child: const Text('Create Topomap'),
            ),
            const SizedBox(height: 20), // Space between buttons
            const SizedBox(height: 20), // Space between text and bottom button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Navigate()),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: const Text('Navigate'),
            ),
          ],
        ),
    );
  }
}

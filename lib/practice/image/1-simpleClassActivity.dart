import 'package:flutter/material.dart';

// -- Images example --

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            // Top image
            Expanded(
              child: Center(
                child: Transform.scale(
                  scale: 1.0,
                  child: Image.asset(
                    'assets/images/green.png',
                    fit: BoxFit.contain
                  )
                ),
              ),
            ),

            // Small space between
            const SizedBox(height: 10),

            // Bottom image
            Expanded(
              child: Center(
                child: Transform.scale(
                  scale: 1.0,
                  child: Image.asset(
                    'assets/images/foz.png',
                    fit: BoxFit.contain
                  )
                )
              )
            ),
          ],
        ),
      ),
    );
  }
}

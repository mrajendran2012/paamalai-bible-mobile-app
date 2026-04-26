import 'package:flutter/material.dart';

/// Stub. Real implementation: see specs/0003-daily-devotion/.
class DevotionScreen extends StatelessWidget {
  const DevotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today’s Devotion')),
      body: const Center(child: Text('Daily devotion UI goes here (FR-DD-01..05).')),
    );
  }
}

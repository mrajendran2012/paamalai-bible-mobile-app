import 'package:flutter/material.dart';

/// Stub. Real implementation: see specs/0001-bible-reader/.
class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reader')),
      body: const Center(child: Text('Bible reader UI goes here (FR-BR-01..04).')),
    );
  }
}

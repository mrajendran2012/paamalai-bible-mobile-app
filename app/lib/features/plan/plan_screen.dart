import 'package:flutter/material.dart';

/// Stub. Real implementation: see specs/0002-yearly-plan/.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today’s Plan')),
      body: const Center(child: Text('Yearly plan UI goes here (FR-YP-01..04).')),
    );
  }
}

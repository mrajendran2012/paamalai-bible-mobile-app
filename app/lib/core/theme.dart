import 'package:flutter/material.dart';

const _seed = Color(0xFF7C3AED); // Paamalai violet

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _seed),
  textTheme: _readingTextTheme(Brightness.light),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
  textTheme: _readingTextTheme(Brightness.dark),
);

TextTheme _readingTextTheme(Brightness b) {
  final base = (b == Brightness.dark)
      ? const TextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white)
      : const TextTheme();
  return base.apply(fontFamilyFallback: const ['NotoSansTamil']);
}

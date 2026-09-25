import 'package:flutter/material.dart';

/// Warm, domestic palette — deliberately not clinical blue/green.
const _seed = Color(0xFF8A4B2F);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 10),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Member colours. Always shown together with initials/names, never alone.
const memberColors = [
  Color(0xFF8A4B2F),
  Color(0xFF2F6B8A),
  Color(0xFF6B8A2F),
  Color(0xFF7A2F8A),
  Color(0xFF8A2F4B),
  Color(0xFF2F8A73),
  Color(0xFF8A7A2F),
  Color(0xFF4B4B8A),
];

Color memberColor(int index) => memberColors[index % memberColors.length];

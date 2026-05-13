import 'package:flutter/material.dart';

class ThemeEngine {
  /// Generates a ThemeData object from a YAML definition.
  static ThemeData parseTheme(Map<String, dynamic>? themeDef) {
    if (themeDef == null) {
      return ThemeData.light(); // Default
    }

    final isDark = themeDef['brightness'] == 'dark';
    
    // Parse colors
    final colorsDef = themeDef['colors'] as Map<String, dynamic>? ?? {};
    final primaryColor = _parseColor(colorsDef['primary']);
    final scaffoldBackgroundColor = _parseColor(colorsDef['background']);

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: _parseColor(colorsDef['appBar']),
      ),
      // Extend with typography, spacing, radius as needed
    );
  }

  static Color? _parseColor(dynamic colorStr) {
    if (colorStr == null) return null;
    final hexCode = colorStr.toString().replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('0xFF$hexCode'));
    } else if (hexCode.length == 8) {
      return Color(int.parse('0x$hexCode'));
    }
    return null;
  }
}

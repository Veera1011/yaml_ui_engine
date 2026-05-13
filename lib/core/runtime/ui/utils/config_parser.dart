import 'package:flutter/material.dart';
import 'package:string_to_icon/string_to_icon.dart';

class ConfigParser {
  /// Parses a color string (e.g., "#FF0000" or "0xFF0000").
  static Color? parseColor(dynamic colorStr) {
    if (colorStr == null) return null;
    final str = colorStr.toString().replaceAll('#', '');
    if (str.length == 6) {
      return Color(int.parse('0xFF$str'));
    } else if (str.length == 8) {
      return Color(int.parse('0x$str'));
    }
    return null;
  }

  /// Parses edge insets from a number, string, or map.
  static EdgeInsetsGeometry? parseEdgeInsets(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return EdgeInsets.all(value.toDouble());
    } else if (value is String) {
      final val = double.tryParse(value);
      if (val != null) {
        return EdgeInsets.all(val);
      }
      // Handle "8,16,8,16"
      final parts = value.split(',');
      if (parts.length == 4) {
        return EdgeInsets.fromLTRB(
          double.parse(parts[0].trim()),
          double.parse(parts[1].trim()),
          double.parse(parts[2].trim()),
          double.parse(parts[3].trim()),
        );
      }
    } else if (value is Map) {
      return EdgeInsets.only(
        left: double.tryParse(value['left']?.toString() ?? '0') ?? 0,
        top: double.tryParse(value['top']?.toString() ?? '0') ?? 0,
        right: double.tryParse(value['right']?.toString() ?? '0') ?? 0,
        bottom: double.tryParse(value['bottom']?.toString() ?? '0') ?? 0,
      );
    }
    return null;
  }

  /// Parses an alignment string (e.g., "center", "topLeft").
  static AlignmentGeometry? parseAlignment(dynamic value) {
    if (value == null) return null;
    final str = value.toString().toLowerCase().replaceAll('_', '');
    
    // Check standard Alignment values
    try {
      if (str.contains('center')) {
        if (str == 'center') return Alignment.center;
        if (str == 'centerleft') return Alignment.centerLeft;
        if (str == 'centerright') return Alignment.centerRight;
      }
      if (str.contains('top')) {
        if (str == 'topcenter') return Alignment.topCenter;
        if (str == 'topleft') return Alignment.topLeft;
        if (str == 'topright') return Alignment.topRight;
      }
      if (str.contains('bottom')) {
        if (str == 'bottomcenter') return Alignment.bottomCenter;
        if (str == 'bottomleft') return Alignment.bottomLeft;
        if (str == 'bottomright') return Alignment.bottomRight;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Parses a text style definition map.
  static TextStyle? parseTextStyle(dynamic def) {
    if (def == null || def is! Map) return null;

    return TextStyle(
      color: parseColor(def['color']),
      fontSize: double.tryParse(def['fontSize']?.toString() ?? ''),
      fontWeight: _parseFontWeight(def['fontWeight']),
      fontStyle: def['fontStyle'] == 'italic' ? FontStyle.italic : FontStyle.normal,
    );
  }

  static FontWeight? _parseFontWeight(dynamic weight) {
    if (weight == null) return null;
    final str = weight.toString();
    switch (str) {
      case 'normal':
      case '400':
        return FontWeight.normal;
      case 'bold':
      case '700':
        return FontWeight.bold;
      case '100': return FontWeight.w100;
      case '200': return FontWeight.w200;
      case '300': return FontWeight.w300;
      case '500': return FontWeight.w500;
      case '600': return FontWeight.w600;
      case '800': return FontWeight.w800;
      case '900': return FontWeight.w900;
      default: return null;
    }
  }

  static TextAlign? parseTextAlign(dynamic value) {
    if (value == null) return null;
    final str = value.toString().toLowerCase();
    return TextAlign.values.firstWhere(
      (e) => e.name.toLowerCase() == str,
      orElse: () => TextAlign.start,
    );
  }

  static MainAxisAlignment parseMainAxisAlignment(dynamic value) {
    if (value == null) return MainAxisAlignment.start;
    final str = value.toString().toLowerCase().replaceAll('_', '');
    return MainAxisAlignment.values.firstWhere(
      (e) => e.name.toLowerCase() == str,
      orElse: () => MainAxisAlignment.start,
    );
  }

  static CrossAxisAlignment parseCrossAxisAlignment(dynamic value) {
    if (value == null) return CrossAxisAlignment.center; // default for Row
    final str = value.toString().toLowerCase().replaceAll('_', '');
    return CrossAxisAlignment.values.firstWhere(
      (e) => e.name.toLowerCase() == str,
      orElse: () => CrossAxisAlignment.center,
    );
  }

  /// Parses a string to Material IconData
  static IconData? parseIconData(String? iconName) {
    if (iconName == null) return null;
    return IconMapper.getIconData(iconName);
  }

  /// Parses a BoxDecoration map
  static BoxDecoration? parseBoxDecoration(dynamic def) {
    if (def == null || def is! Map) return null;

    final borderRadius = double.tryParse(def['borderRadius']?.toString() ?? '');

    return BoxDecoration(
      color: parseColor(def['color']),
      image: parseDecorationImage(def['image']),
      border: parseBorder(def['border']),
      borderRadius: borderRadius != null ? BorderRadius.circular(borderRadius) : null,
      boxShadow: parseBoxShadow(def['boxShadow']),
      gradient: parseGradient(def['gradient']),
      shape: def['shape'] == 'circle' ? BoxShape.circle : BoxShape.rectangle,
    );
  }

  /// Parses a Gradient definition
  static Gradient? parseGradient(dynamic def) {
    if (def == null || def is! Map) return null;

    final colors = (def['colors'] as List<dynamic>?)
            ?.map((c) => parseColor(c) ?? Colors.transparent)
            .toList() ??
        [];
    final stops = (def['stops'] as List<dynamic>?)
        ?.map((s) => double.tryParse(s.toString()) ?? 0.0)
        .toList();

    if (def['type'] == 'radial') {
      return RadialGradient(
        colors: colors,
        stops: stops,
        center: parseAlignment(def['center']) as Alignment? ?? Alignment.center,
        radius: double.tryParse(def['radius']?.toString() ?? '0.5') ?? 0.5,
      );
    }

    return LinearGradient(
      colors: colors,
      stops: stops,
      begin: parseAlignment(def['begin']) as Alignment? ?? Alignment.centerLeft,
      end: parseAlignment(def['end']) as Alignment? ?? Alignment.centerRight,
    );
  }

  /// Parses a DecorationImage
  static DecorationImage? parseDecorationImage(dynamic def) {
    if (def == null) return null;
    if (def is String) {
      return DecorationImage(
        image: def.startsWith('http') ? NetworkImage(def) : AssetImage(def) as ImageProvider,
        fit: BoxFit.cover,
      );
    }
    if (def is Map) {
      final src = def['src']?.toString();
      if (src == null) return null;
      return DecorationImage(
        image: src.startsWith('http') ? NetworkImage(src) : AssetImage(src) as ImageProvider,
        fit: _parseBoxFit(def['fit']),
      );
    }
    return null;
  }

  static BoxFit _parseBoxFit(dynamic value) {
    if (value == null) return BoxFit.cover;
    return BoxFit.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toString().toLowerCase(),
      orElse: () => BoxFit.cover,
    );
  }

  /// Parses BoxConstraints
  static BoxConstraints? parseBoxConstraints(dynamic def) {
    if (def == null || def is! Map) return null;
    return BoxConstraints(
      minWidth: double.tryParse(def['minWidth']?.toString() ?? '0.0') ?? 0.0,
      maxWidth: double.tryParse(def['maxWidth']?.toString() ?? 'double.infinity') ?? double.infinity,
      minHeight: double.tryParse(def['minHeight']?.toString() ?? '0.0') ?? 0.0,
      maxHeight: double.tryParse(def['maxHeight']?.toString() ?? 'double.infinity') ?? double.infinity,
    );
  }

  /// Parses a list of BoxShadow definitions
  static List<BoxShadow>? parseBoxShadow(dynamic defs) {
    if (defs == null || defs is! List) return null;
    
    return defs.map((def) {
      if (def is! Map) return const BoxShadow();
      return BoxShadow(
        color: parseColor(def['color']) ?? Colors.black26,
        blurRadius: double.tryParse(def['blurRadius']?.toString() ?? '0') ?? 0,
        spreadRadius: double.tryParse(def['spreadRadius']?.toString() ?? '0') ?? 0,
        offset: Offset(
          double.tryParse(def['offsetX']?.toString() ?? '0') ?? 0,
          double.tryParse(def['offsetY']?.toString() ?? '0') ?? 0,
        ),
      );
    }).toList();
  }

  /// Parses a Border configuration
  static Border? parseBorder(dynamic def) {
    if (def == null || def is! Map) return null;
    
    final color = parseColor(def['color']) ?? Colors.black;
    final width = double.tryParse(def['width']?.toString() ?? '1.0') ?? 1.0;
    
    return Border.all(color: color, width: width);
  }
}

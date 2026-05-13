import 'package:yaml/yaml.dart';

class YamlParser {
  /// Parses a YAML string into a Map<String, dynamic>.
  static Map<String, dynamic> parse(String yamlString) {
    try {
      final document = loadYaml(yamlString);
      return _convertNode(document);
    } catch (e) {
      throw FormatException("Failed to parse YAML: $e");
    }
  }

  /// Recursively converts YamlMap and YamlList to standard Dart Map and List.
  static dynamic _convertNode(dynamic node) {
    if (node is YamlMap) {
      final map = <String, dynamic>{};
      node.forEach((key, value) {
        map[key.toString()] = _convertNode(value);
      });
      return map;
    } else if (node is YamlList) {
      return node.map((item) => _convertNode(item)).toList();
    }
    return node;
  }

  /// Converts a Map back to a YAML string.
  static String toYaml(Map<String, dynamic> map, {int indent = 0}) {
    final sb = StringBuffer();
    final spaces = '  ' * indent;
    
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        sb.writeln('$spaces$key:');
        sb.write(toYaml(value, indent: indent + 1));
      } else if (value is List) {
        sb.writeln('$spaces$key:');
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final nested = toYaml(item, indent: indent + 1);
            sb.write('$spaces- ${nested.trimLeft()}');
          } else {
            sb.writeln('$spaces- $item');
          }
        }
      } else {
        sb.writeln('$spaces$key: "$value"');
      }
    });
    
    return sb.toString();
  }
}

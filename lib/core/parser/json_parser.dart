import 'dart:convert';

class JsonParser {
  /// Parses a JSON string into a Map.
  static Map<String, dynamic> parse(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is List) {
        // If it's a list, we wrap it in a Map with an 'items' key.
        return {'items': decoded};
      }
      return {};
    } catch (e) {
      throw FormatException("Failed to parse JSON: $e");
    }
  }

  /// Converts a Map back to a JSON string.
  static String toJson(Map<String, dynamic> map, {bool pretty = false}) {
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(map);
    }
    return json.encode(map);
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageEngine {
  static const String _keyPrefix = 'yaml_ui_engine_';

  /// Saves a key-value pair to local storage.
  static Future<void> save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonValue = jsonEncode(value);
    await prefs.setString('$_keyPrefix$key', jsonValue);
  }

  /// Loads a value from local storage.
  static Future<dynamic> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonValue = prefs.getString('$_keyPrefix$key');
    if (jsonValue != null) {
      return jsonDecode(jsonValue);
    }
    return null;
  }

  /// Saves the entire state map.
  static Future<void> saveState(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_keyPrefix}global_state', jsonEncode(state));
  }

  /// Loads the entire state map.
  static Future<Map<String, dynamic>> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonValue = prefs.getString('${_keyPrefix}global_state');
    if (jsonValue != null) {
      return Map<String, dynamic>.from(jsonDecode(jsonValue));
    }
    return {};
  }

  /// Clears stored state.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_keyPrefix}global_state');
  }
}

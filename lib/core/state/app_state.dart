import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../operations/operation_engine.dart';
import '../storage/storage_engine.dart';

/// A Riverpod Notifier to manage the global dynamic state of the application.
class AppStateNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    return {
      'device': {
        'width': 0.0,
        'height': 0.0,
        'isMobile': true,
        'isTablet': false,
        'isDesktop': false,
        'orientation': 'portrait',
      }
    };
  }

  Map<String, String> _computedDefinitions = {};
  Set<String> _persistentKeys = {};

  /// Sets the initial state, persistent keys, and computed definitions.
  void initialize({
    Map<String, dynamic>? initialState,
    List<dynamic>? persist,
    Map<dynamic, dynamic>? computed,
  }) {
    _persistentKeys = persist?.map((e) => e.toString()).toSet() ?? {};
    _computedDefinitions = computed?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {};

    state = {
      ...state,
      if (initialState != null) ...initialState,
    };

    // Load persistent values
    for (final key in _persistentKeys) {
      StorageEngine.load(key).then((value) {
        if (value != null) {
          setValue(key, value, saveToStorage: false);
        }
      });
    }

    recalculateComputed();
  }

  /// Sets a value in the state.
  void setValue(String key, dynamic value, {bool saveToStorage = true}) {
    if (state[key] == value) return; // No change
    state = {
      ...state,
      key: value,
    };

    if (saveToStorage && _persistentKeys.contains(key)) {
      StorageEngine.save(key, value);
    }

    recalculateComputed();
    _notifyListeners(key, value);
  }

  /// Recalculates all computed properties based on current state.
  void recalculateComputed() {
    if (_computedDefinitions.isEmpty) return;
    
    final newState = Map<String, dynamic>.from(state);
    var changed = false;

    _computedDefinitions.forEach((key, expression) {
      final newValue = OperationEngine.evaluate(expression, newState);
      if (newState[key] != newValue) {
        newState[key] = newValue;
        changed = true;
      }
    });

    if (changed) {
      state = newState;
    }
  }

  final List<void Function(String key, dynamic value)> _listeners = [];

  void addListener(void Function(String key, dynamic value) listener) {
    _listeners.add(listener);
  }

  void _notifyListeners(String key, dynamic value) {
    for (final listener in _listeners) {
      listener(key, value);
    }
  }

  /// Gets a value from the state.
  dynamic getValue(String key) {
    return state[key];
  }

  /// Updates multiple values at once.
  void setValues(Map<String, dynamic> values) {
    state = {
      ...state,
      ...values,
    };
  }

  /// Updates device metrics for responsiveness.
  void updateMetrics({
    required double width,
    required double height,
    required Orientation orientation,
  }) {
    final device = {
      'width': width,
      'height': height,
      'isMobile': width < 600,
      'isTablet': width >= 600 && width < 1024,
      'isDesktop': width >= 1024,
      'orientation': orientation == Orientation.portrait ? 'portrait' : 'landscape',
    };
    
    if (jsonEncode(state['device']) != jsonEncode(device)) {
      state = { ...state, 'device': device };
      recalculateComputed();
    }
  }

  /// Clears the state.
  void clear() {
    state = {};
  }
}

/// The global provider for the App State.
final appStateProvider = NotifierProvider<AppStateNotifier, Map<String, dynamic>>(() {
  return AppStateNotifier();
});

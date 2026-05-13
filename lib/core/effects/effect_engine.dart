import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../actions/action_engine.dart';

class EffectEngine {
  static List<Map<String, dynamic>> _registeredEffects = [];

  static void setEffects(List<dynamic>? effects) {
    if (effects == null) return;
    _registeredEffects = effects.map((e) => e as Map<String, dynamic>).toList();
  }

  static void onStateChanged(BuildContext context, WidgetRef ref, String key, dynamic value) {
    for (final effect in _registeredEffects) {
      if (effect['watch'] == key) {
        final action = effect['action'];
        if (action != null) {
          ActionEngine.execute(context, ref, action);
        }
      }
    }
  }
}

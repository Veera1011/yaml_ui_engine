import '../operations/operation_engine.dart';

class LogicEngine {
  /// Evaluates logic conditions on a widget definition to determine if it should be shown.
  static bool isVisible(Map<String, dynamic> definition, Map<String, dynamic> state) {
    if (definition.containsKey('visibleIf')) {
      return _evaluateCondition(definition['visibleIf'], state);
    }
    if (definition.containsKey('hiddenIf')) {
      return !_evaluateCondition(definition['hiddenIf'], state);
    }
    return true;
  }

  /// Evaluates logic conditions to determine if a widget should be enabled.
  static bool isEnabled(Map<String, dynamic> definition, Map<String, dynamic> state) {
    if (definition.containsKey('enabledIf')) {
      return _evaluateCondition(definition['enabledIf'], state);
    }
    return true;
  }

  static bool _evaluateCondition(dynamic condition, Map<String, dynamic> state) {
    if (condition == null) return true;

    // Handle complex groups
    if (condition is Map) {
      if (condition.containsKey('matchAll')) {
        final list = condition['matchAll'] as List;
        return list.every((item) => _evaluateCondition(item, state));
      }
      if (condition.containsKey('matchAny')) {
        final list = condition['matchAny'] as List;
        return list.any((item) => _evaluateCondition(item, state));
      }
    }

    // Default: evaluate as expression
    final result = OperationEngine.evaluate(condition.toString(), state);
    return result == true || result == 'true';
  }
}

import '../operations/operation_engine.dart';

class RuleEngine {
  /// Evaluates a boolean property (like required, hidden, disabled) based on a condition.
  /// Supports raw boolean, string expression, or a Map with 'if' key.
  static bool evaluateProperty(dynamic definition, Map<String, dynamic> state, {bool defaultValue = false}) {
    if (definition == null) return defaultValue;
    if (definition is bool) return definition;
    
    // Support "requiredIf: '{{type == ...}}'"
    final result = OperationEngine.evaluate(definition.toString(), state);
    return result == true || result == 'true';
  }

  /// Evaluates a value (like defaultValue) based on a condition.
  static dynamic evaluateValue(dynamic definition, Map<String, dynamic> state) {
    if (definition == null) return null;
    
    if (definition is Map && definition.containsKey('valueIf')) {
      final condition = definition['condition']?.toString() ?? 'true';
      final result = OperationEngine.evaluate(condition, state);
      if (result == true || result == 'true') {
        return OperationEngine.evaluate(definition['valueIf'].toString(), state);
      }
      return definition['elseValue'];
    }

    return OperationEngine.evaluate(definition.toString(), state);
  }
}

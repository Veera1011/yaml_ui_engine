import 'package:expressions/expressions.dart';

class OperationEngine {
  /// Evaluates an expression like "{{qty * price}}" against the provided state.
  /// If the string doesn't contain "{{...}}", it returns the original string.
  static dynamic evaluate(String input, Map<String, dynamic> state) {
    if (!input.contains('{{') || !input.contains('}}')) {
      return input;
    }

    // Handle template strings, e.g., "Welcome {{username}}"
    // For simplicity in MVP, we first check if the whole string is an expression:
    final exactMatch = RegExp(r'^\{\{(.+)\}\}$').firstMatch(input.trim());
    if (exactMatch != null) {
      final expressionString = exactMatch.group(1)!;
      return _evaluateExpression(expressionString, state);
    }

    // Otherwise, replace occurrences within the string
    return input.replaceAllMapped(RegExp(r'\{\{(.*?)\}\}'), (match) {
      final expressionString = match.group(1)!;
      final result = _evaluateExpression(expressionString, state);
      return result?.toString() ?? '';
    });
  }

  static dynamic _evaluateExpression(String expressionString, Map<String, dynamic> state) {
    try {
      final expression = Expression.parse(expressionString);
      
      // Inject functional helpers into context
      final context = {
        ...state,
        'upper': (dynamic s) => s?.toString().toUpperCase(),
        'lower': (dynamic s) => s?.toString().toLowerCase(),
        'round': (dynamic n) => (n is num) ? n.round() : double.tryParse(n.toString())?.round(),
        'min': (dynamic a, dynamic b) => (a is num && b is num) ? (a < b ? a : b) : a,
        'max': (dynamic a, dynamic b) => (a is num && b is num) ? (a > b ? a : b) : a,
        'coalesce': (dynamic a, dynamic b) => a ?? b,
        'length': (dynamic val) {
          if (val is String) return val.length;
          if (val is List) return val.length;
          if (val is Map) return val.length;
          return 0;
        },
      };

      final evaluator = ExpressionEvaluator(memberAccessors: [
        MapMemberAccessor(),
      ]);
      return evaluator.eval(expression, context);
    } catch (e) {
      print("Expression evaluation error for '$expressionString': $e");
      return null;
    }
  }
}

class MapMemberAccessor implements MemberAccessor {
  @override
  bool canHandle(dynamic object, String member) => object is Map;

  @override
  dynamic getMember(dynamic object, String member) {
    if (object is Map) {
      return object[member];
    }
    return null;
  }
}

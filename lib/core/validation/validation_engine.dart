import '../operations/operation_engine.dart';
import '../rules/rule_engine.dart';

class ValidationEngine {
  /// Validates a value against a set of rules defined in the YAML configuration.
  /// Rules can be a Map or a List of Maps.
  /// Returns a validation error message if invalid, or null if valid.
  static String? validate(dynamic value, dynamic rules, Map<String, dynamic> state) {
    if (rules == null) return null;

    if (rules is List) {
      for (final rule in rules) {
        final error = _validateSingleRule(value, rule as Map<String, dynamic>, state);
        if (error != null) return error;
      }
      return null;
    } else if (rules is Map<String, dynamic>) {
      return _validateSingleRule(value, rules, state);
    }

    return null;
  }

  static String? _validateSingleRule(dynamic value, Map<String, dynamic> rules, Map<String, dynamic> state) {
    final stringValue = value?.toString() ?? '';

    // Required
    final isRequired = rules['required'] == true || 
                       RuleEngine.evaluateProperty(rules['requiredIf'], state);

    if (isRequired && stringValue.trim().isEmpty) {
      return rules['message'] ?? rules['requiredMessage'] ?? 'This field is required';
    }

    if (stringValue.trim().isEmpty) return null; // Don't validate other rules if empty and not required

    // Email
    if (rules['type'] == 'email' || rules['email'] == true) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(stringValue)) {
        return rules['message'] ?? 'Invalid email address';
      }
    }

    // Numeric
    if (rules['type'] == 'numeric' || rules['numeric'] == true) {
      if (double.tryParse(stringValue) == null) {
        return rules['message'] ?? 'Must be a number';
      }
    }

    // Min Length
    if (rules.containsKey('minLength')) {
      final minLength = int.tryParse(rules['minLength'].toString()) ?? 0;
      if (stringValue.length < minLength) {
        return rules['message'] ?? rules['minLengthMessage'] ?? 'Minimum length is $minLength';
      }
    }

    // Max Length
    if (rules.containsKey('maxLength')) {
      final maxLength = int.tryParse(rules['maxLength'].toString()) ?? 0;
      if (stringValue.length > maxLength) {
        return rules['message'] ?? rules['maxLengthMessage'] ?? 'Maximum length is $maxLength';
      }
    }

    // Regex
    if (rules.containsKey('regex')) {
      final regexStr = rules['regex'].toString();
      final regex = RegExp(regexStr);
      if (!regex.hasMatch(stringValue)) {
        return rules['message'] ?? rules['regexMessage'] ?? 'Invalid format';
      }
    }

    // Match Field (e.g. password confirmation)
    if (rules.containsKey('matchField')) {
      final otherField = rules['matchField'].toString();
      final otherValue = state[otherField]?.toString() ?? '';
      if (stringValue != otherValue) {
        return rules['message'] ?? 'Fields do not match';
      }
    }

    // Custom Rule (Expression)
    if (rules.containsKey('customRule')) {
      final expression = rules['customRule'].toString();
      final result = OperationEngine.evaluate(expression, state);
      if (result != true) {
        return rules['message'] ?? 'Validation failed';
      }
    }

    return null;
  }
}

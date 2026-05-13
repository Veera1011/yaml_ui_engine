import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/app_state.dart';
import '../operations/operation_engine.dart';

class ApiEngine {
  /// Executes an API call defined by the [actionDef].
  /// Executes an API call defined by the [actionDef].
  static Future<Map<String, dynamic>> executeApi(WidgetRef ref, Map<String, dynamic> actionDef) async {
    final method = actionDef['method']?.toString().toUpperCase() ?? 'GET';
    final rawUrl = actionDef['url']?.toString() ?? '';
    final loadingKey = actionDef['loadingKey']?.toString();
    
    final state = ref.read(appStateProvider);
    final url = OperationEngine.evaluate(rawUrl, state).toString();

    if (loadingKey != null) {
      ref.read(appStateProvider.notifier).setValue(loadingKey, true);
    }

    // Resolve Body
    final rawBody = actionDef['body'];
    dynamic resolvedBody;
    if (rawBody is Map) {
      final bodyMap = <String, dynamic>{};
      rawBody.forEach((key, value) {
        bodyMap[key.toString()] = OperationEngine.evaluate(value.toString(), state);
      });
      resolvedBody = jsonEncode(bodyMap);
    } else if (rawBody != null) {
      resolvedBody = OperationEngine.evaluate(rawBody.toString(), state);
    }

    // Prepare Headers (inject global auth token if present)
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (state['auth_token'] != null) {
      headers['Authorization'] = 'Bearer ${state['auth_token']}';
    }
    if (actionDef['headers'] is Map) {
      (actionDef['headers'] as Map).forEach((key, value) {
        headers[key.toString()] = OperationEngine.evaluate(value.toString(), state).toString();
      });
    }

    try {
      final uri = Uri.parse(url);
      http.Response response;

      switch (method) {
        case 'POST':
          response = await http.post(uri, headers: headers, body: resolvedBody);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: resolvedBody);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: resolvedBody);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          response = await http.get(uri, headers: headers);
      }

      if (loadingKey != null) {
        ref.read(appStateProvider.notifier).setValue(loadingKey, false);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        
        // Handle Response Mapping
        final mapping = actionDef['responseMapping'] as Map<String, dynamic>?;
        if (mapping != null) {
          mapping.forEach((stateKey, dataPath) {
            final value = _getValueByPath(data, dataPath.toString());
            ref.read(appStateProvider.notifier).setValue(stateKey, value);
          });
        } else if (actionDef['stateKey'] != null) {
          // Direct save
          ref.read(appStateProvider.notifier).setValue(actionDef['stateKey'].toString(), data);
        }

        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Status: ${response.statusCode}'};
      }
    } catch (e) {
      if (loadingKey != null) {
        ref.read(appStateProvider.notifier).setValue(loadingKey, false);
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  static dynamic _getValueByPath(dynamic data, String path) {
    if (path == r"$" || path.isEmpty) return data;
    final parts = path.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part.replaceAll('[', '').replaceAll(']', ''));
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../navigation/navigation_engine.dart';
import '../api/api_engine.dart';
import '../state/app_state.dart';
import '../permissions/permission_engine.dart';
import '../validation/validation_engine.dart';
import '../operations/operation_engine.dart';
import '../workflow/workflow_engine.dart';
import '../focus/focus_engine.dart';

class ActionEngine {
  /// Executes a dynamic action (or list of actions) based on its definition.
  /// [contextMap] is a local scope for sharing data between workflow steps.
  static Future<void> execute(BuildContext context, WidgetRef ref, dynamic actionDef, {Map<String, dynamic>? contextMap}) async {
    // Check permissions before execution
    final state = ref.read(appStateProvider);
    final combinedState = Map<String, dynamic>.from(state);
    if (contextMap != null) combinedState['context'] = contextMap;

    if (actionDef is Map<String, dynamic>) {
       if (!PermissionEngine.hasPermission(actionDef, combinedState)) {
         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Access Denied: You do not have permission to perform this action.')),
           );
         }
         return;
       }
    }

    if (actionDef is List) {
      for (final action in actionDef) {
        await _executeSingleAction(context, ref, action as Map<String, dynamic>, contextMap: contextMap);
      }
    } else if (actionDef is Map<String, dynamic>) {
      await _executeSingleAction(context, ref, actionDef, contextMap: contextMap);
    }
  }

  static Future<void> _executeSingleAction(BuildContext context, WidgetRef ref, Map<String, dynamic> actionDef, {Map<String, dynamic>? contextMap}) async {
    final type = actionDef['type'] as String?;
    final state = ref.read(appStateProvider);
    final combinedState = Map<String, dynamic>.from(state);
    if (contextMap != null) combinedState['context'] = contextMap;

    switch (type) {
      case 'navigate':
        final route = actionDef['route'] as String?;
        if (route != null) {
          NavigationEngine.navigate(context, route);
        }
        break;
      case 'snackbar':
      case 'snack':
        final message = actionDef['message'] as String?;
        if (message != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
        break;
      case 'api':
        final result = await ApiEngine.executeApi(ref, actionDef);
        if (result['success'] == true) {
           final onSuccess = actionDef['onSuccess'];
           if (onSuccess != null && context.mounted) {
              await execute(context, ref, onSuccess);
           }
        } else {
           final onError = actionDef['onError'];
           if (onError != null && context.mounted) {
              await execute(context, ref, onError);
           } else if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('API Error: ${result['error']}')),
            );
           }
        }
        break;
      case 'setState':
        final key = actionDef['key'] as String?;
        final value = actionDef['value'];
        if (key != null) {
          ref.read(appStateProvider.notifier).setValue(key, value);
        }
        break;
      case 'validateForm':
        final fields = actionDef['fields'] as List<dynamic>? ?? [];
        final state = ref.read(appStateProvider);
        var isValid = true;

        for (final fieldDef in fields) {
          if (fieldDef is Map<String, dynamic>) {
            final name = fieldDef['name']?.toString();
            final rules = fieldDef['validation'];
            if (name != null) {
              final value = state[name];
              final error = ValidationEngine.validate(value, rules, state);
              ref.read(appStateProvider.notifier).setValue('${name}_error', error);
              if (error != null) isValid = false;
            }
          }
        }

        if (isValid) {
          final onSuccess = actionDef['onSuccess'];
          if (onSuccess != null && context.mounted) {
            await execute(context, ref, onSuccess, contextMap: contextMap);
          }
        } else {
          final onError = actionDef['onError'];
          if (onError != null && context.mounted) {
            await execute(context, ref, onError, contextMap: contextMap);
          }
        }
        break;
      case 'focus':
        final targetId = actionDef['id']?.toString();
        if (targetId != null) {
          FocusEngine.focus(targetId);
        }
        break;
      case 'scrollTo':
        final targetId = actionDef['id']?.toString();
        if (targetId != null) {
          FocusEngine.scrollTo(targetId);
        }
        break;
      case 'workflow':
        await WorkflowEngine.executeWorkflow(context, ref, actionDef);
        break;
      case 'if':
        final condition = actionDef['condition']?.toString() ?? 'false';
        final result = OperationEngine.evaluate(condition, combinedState);
        if (result == true || result == 'true') {
          final thenAction = actionDef['then'];
          if (thenAction != null) await execute(context, ref, thenAction, contextMap: contextMap);
        } else {
          final elseAction = actionDef['else'];
          if (elseAction != null) await execute(context, ref, elseAction, contextMap: contextMap);
        }
        break;
      case 'delay':
        final duration = int.tryParse(actionDef['duration']?.toString() ?? '0') ?? 0;
        await Future.delayed(Duration(milliseconds: duration));
        break;
      case 'forEach':
        final itemsRaw = actionDef['items'];
        final items = itemsRaw is String 
            ? (OperationEngine.evaluate(itemsRaw, combinedState) as List<dynamic>? ?? [])
            : (itemsRaw as List<dynamic>? ?? []);
        
        final iteratorName = actionDef['iterator']?.toString() ?? 'item';
        final loopAction = actionDef['action'];

        if (loopAction != null) {
          for (final item in items) {
            final localContext = {...?contextMap, iteratorName: item};
            await execute(context, ref, loopAction, contextMap: localContext);
          }
        }
        break;
      case 'confirm':
      case 'dialog':
        if (!context.mounted) break;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(actionDef['title']?.toString() ?? 'Confirm'),
            content: Text(actionDef['message']?.toString() ?? 'Are you sure?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(actionDef['cancelText']?.toString() ?? 'Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(actionDef['confirmText']?.toString() ?? 'Confirm')),
            ],
          ),
        );
        if (confirmed == true) {
          final onConfirm = actionDef['onConfirm'];
          if (onConfirm != null && context.mounted) await execute(context, ref, onConfirm, contextMap: contextMap);
        } else {
          final onCancel = actionDef['onCancel'];
          if (onCancel != null && context.mounted) await execute(context, ref, onCancel, contextMap: contextMap);
        }
        break;
      default:
        break;
    }
  }
}

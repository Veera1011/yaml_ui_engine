import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../actions/action_engine.dart';

class WorkflowEngine {
  /// Executes a multi-step sequential operation (workflow).
  static Future<void> executeWorkflow(BuildContext context, WidgetRef ref, Map<String, dynamic> workflowDef) async {
    final steps = workflowDef['steps'] as List<dynamic>? ?? [];
    final Map<String, dynamic> localContext = {};

    try {
      for (final step in steps) {
        if (step is Map<String, dynamic>) {
          if (!context.mounted) break;
          await ActionEngine.execute(context, ref, step, contextMap: localContext);
        }
      }
    } catch (e) {
      final onErrorAction = workflowDef['onError'];
      if (onErrorAction != null && context.mounted) {
        await ActionEngine.execute(context, ref, onErrorAction, contextMap: {'error': e.toString()});
      } else {
        rethrow;
      }
    }
  }
}

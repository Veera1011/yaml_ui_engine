import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../registry/widget_registry.dart';
import '../../../state/app_state.dart';
import '../../../operations/operation_engine.dart';
import '../../../actions/action_engine.dart';
import '../../../validation/validation_engine.dart';
import '../../../rules/rule_engine.dart';
import '../../../focus/focus_engine.dart';
import '../utils/config_parser.dart';

void registerBaseWidgets() {
  WidgetRegistry.register('text', (context, definition, localContext, path) {
    final rawValue = definition['value']?.toString() ?? '';
    final resolvedValue = OperationEngine.evaluate(rawValue, localContext).toString();
    
    return Text(
      resolvedValue,
      style: ConfigParser.parseTextStyle(definition['style']),
      textAlign: ConfigParser.parseTextAlign(definition['textAlign']),
      maxLines: int.tryParse(definition['maxLines']?.toString() ?? ''),
    );
  });

  WidgetRegistry.register('textfield', (context, definition, localContext, path) {
    return Consumer(
      builder: (context, ref, child) {
        final name = definition['name'] as String?;
        if (name == null) return const Text('Error: TextField missing "name"');
        
        final state = ref.watch(appStateProvider);
        final initialValue = state[name]?.toString() ?? '';
        final validationRules = definition['validation'];

        final isEnabled = !RuleEngine.evaluateProperty(definition['disabledIf'], localContext);

        final id = definition['id']?.toString();
        final focusNode = id != null ? FocusEngine.getOrCreateNode(id) : null;

        return TextFormField(
          initialValue: initialValue,
          enabled: isEnabled,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: definition['label']?.toString() ?? name,
            hintText: definition['hint']?.toString(),
            errorText: state['${name}_error']?.toString(),
          ),
          onChanged: (value) {
            ref.read(appStateProvider.notifier).setValue(name, value);
            
            // Real-time validation
            if (definition['validateOnChanged'] == true) {
              final error = ValidationEngine.validate(value, validationRules, localContext);
              ref.read(appStateProvider.notifier).setValue('${name}_error', error);
            }
          },
          validator: (value) {
            return ValidationEngine.validate(value, validationRules, localContext);
          },
          obscureText: definition['obscureText'] == true,
          keyboardType: definition['keyboardType'] == 'numeric' ? TextInputType.number : null,
        );
      },
    );
  });

  WidgetRegistry.register('dropdown', (context, definition, localContext, path) {
    return Consumer(
      builder: (context, ref, child) {
        final name = definition['name'] as String?;
        if (name == null) return const Text('Error: Dropdown missing "name"');

        final state = ref.watch(appStateProvider);
        final value = state[name]?.toString();
        final options = (definition['options'] as List<dynamic>?) ?? [];
        final isEnabled = !RuleEngine.evaluateProperty(definition['disabledIf'], localContext);

        return DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: definition['label']?.toString() ?? name,
          ),
          onChanged: isEnabled ? (newValue) {
            ref.read(appStateProvider.notifier).setValue(name, newValue);
          } : null,
          items: options.map<DropdownMenuItem<String>>((opt) {
            final label = opt is Map ? opt['label'].toString() : opt.toString();
            final val = opt is Map ? opt['value'].toString() : opt.toString();
            return DropdownMenuItem<String>(
              value: val,
              child: Text(label),
            );
          }).toList(),
        );
      },
    );
  });

  WidgetRegistry.register('form', (context, definition, localContext, path) {
    final childDef = definition['child'] as Map<String, dynamic>?;
    final name = definition['name']?.toString() ?? 'default_form';
    
    return Form(
      key: ValueKey(name),
      child: childDef != null ? WidgetRegistry.buildWidget(context, childDef, localContext: localContext, path: '$path.child') : const SizedBox(),
    );
  });

  WidgetRegistry.register('button', (context, definition, localContext, path) {
    return Consumer(
      builder: (context, ref, child) {
        final rawText = definition['text']?.toString() ?? 'Button';
        final resolvedText = OperationEngine.evaluate(rawText, localContext).toString();
        
        final color = ConfigParser.parseColor(definition['color']);
        final textColor = ConfigParser.parseColor(definition['textColor']);
        final borderRadiusStr = definition['borderRadius']?.toString();
        final borderRadius = borderRadiusStr != null ? double.tryParse(borderRadiusStr) : null;

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            shape: borderRadius != null 
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius))
              : null,
          ),
          onPressed: () {
            final actionDef = definition['action'];
            if (actionDef != null && actionDef is Map<String, dynamic>) {
               ActionEngine.execute(context, ref, actionDef, contextMap: localContext);
            }
          },
          child: Text(resolvedText),
        );
      },
    );
  });

  WidgetRegistry.register('column', (context, definition, localContext, path) {
    final childrenDef = definition['children'] as List<dynamic>? ?? [];
    return Column(
      mainAxisAlignment: ConfigParser.parseMainAxisAlignment(definition['mainAxisAlignment']),
      crossAxisAlignment: ConfigParser.parseCrossAxisAlignment(definition['crossAxisAlignment']),
      children: childrenDef.asMap().entries
          .map<Widget>((entry) => WidgetRegistry.buildWidget(context, entry.value as Map<String, dynamic>, localContext: localContext, path: '$path.children.${entry.key}'))
          .toList(),
    );
  });

  WidgetRegistry.register('row', (context, definition, localContext, path) {
    final childrenDef = definition['children'] as List<dynamic>? ?? [];
    return Row(
      mainAxisAlignment: ConfigParser.parseMainAxisAlignment(definition['mainAxisAlignment']),
      crossAxisAlignment: ConfigParser.parseCrossAxisAlignment(definition['crossAxisAlignment']),
      children: childrenDef.asMap().entries
          .map<Widget>((entry) => WidgetRegistry.buildWidget(context, entry.value as Map<String, dynamic>, localContext: localContext, path: '$path.children.${entry.key}'))
          .toList(),
    );
  });

  WidgetRegistry.register('container', (context, definition, localContext, path) {
    final childDef = definition['child'] as Map<String, dynamic>?;
    
    final widthStr = definition['width']?.toString();
    final heightStr = definition['height']?.toString();
    final borderRadiusStr = definition['borderRadius']?.toString();
    
    final borderRadius = borderRadiusStr != null ? double.tryParse(borderRadiusStr) : null;
    final boxShadow = ConfigParser.parseBoxShadow(definition['boxShadow']);
    final border = ConfigParser.parseBorder(definition['border']);
    final decoration = ConfigParser.parseBoxDecoration(definition['decoration']);
    
    final hasDecoration = borderRadius != null || boxShadow != null || border != null || decoration != null;
    final color = ConfigParser.parseColor(definition['color']);

    return Container(
      width: widthStr != null ? double.tryParse(widthStr) : null,
      height: heightStr != null ? double.tryParse(heightStr) : null,
      constraints: ConfigParser.parseBoxConstraints(definition['constraints']),
      color: !hasDecoration ? color : null,
      decoration: hasDecoration 
        ? (decoration ?? BoxDecoration(
            color: color,
            borderRadius: borderRadius != null ? BorderRadius.circular(borderRadius) : null,
            boxShadow: boxShadow,
            border: border,
          ))
        : null,
      margin: ConfigParser.parseEdgeInsets(definition['margin']),
      padding: ConfigParser.parseEdgeInsets(definition['padding']),
      alignment: ConfigParser.parseAlignment(definition['alignment']),
      child: childDef != null ? WidgetRegistry.buildWidget(context, childDef, localContext: localContext, path: '$path.child') : null,
    );
  });
}

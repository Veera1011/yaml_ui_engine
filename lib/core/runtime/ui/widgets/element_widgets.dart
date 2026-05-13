import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../registry/widget_registry.dart';
import '../../../state/app_state.dart';
import '../utils/config_parser.dart';

void registerElementWidgets() {
  WidgetRegistry.register('icon', (context, definition, localContext, path) {
    final iconName = definition['icon']?.toString();
    if (iconName == null) return const Text('Error: Icon missing "icon"');

    final size = double.tryParse(definition['size']?.toString() ?? '');
    final color = ConfigParser.parseColor(definition['color']);

    return Icon(
      ConfigParser.parseIconData(iconName),
      size: size,
      color: color,
    );
  });

  WidgetRegistry.register('card', (context, definition, localContext, path) {
    final childDef = definition['child'] as Map<String, dynamic>?;
    
    final color = ConfigParser.parseColor(definition['color']);
    final elevation = double.tryParse(definition['elevation']?.toString() ?? '');
    final margin = ConfigParser.parseEdgeInsets(definition['margin']);
    final borderRadiusStr = definition['borderRadius']?.toString();
    final borderRadius = borderRadiusStr != null ? double.tryParse(borderRadiusStr) : null;
    
    return Card(
      color: color,
      elevation: elevation,
      margin: margin,
      shape: borderRadius != null 
        ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius))
        : null,
      child: childDef != null ? WidgetRegistry.buildWidget(context, childDef, localContext: localContext, path: '$path.child') : null,
    );
  });

  WidgetRegistry.register('switch', (context, definition, localContext, path) {
    return Consumer(
      builder: (context, ref, child) {
        final name = definition['name'] as String?;
        if (name == null) return const Text('Error: Switch missing "name"');

        final state = ref.watch(appStateProvider);
        final value = state[name] == true || state[name] == 'true';
        final activeColor = ConfigParser.parseColor(definition['activeColor']);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: value,
              activeThumbColor: activeColor,
              onChanged: (newValue) {
                ref.read(appStateProvider.notifier).setValue(name, newValue);
              },
            ),
            if (definition['label'] != null) Text(definition['label'].toString()),
          ],
        );
      },
    );
  });
}

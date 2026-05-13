import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../registry/widget_registry.dart';
import '../../../state/app_state.dart';
import '../../../operations/operation_engine.dart';
import '../utils/config_parser.dart';
import '../../../registry/component_registry.dart';

void registerLayoutWidgets() {
  WidgetRegistry.register('expanded', (context, definition, localContext, path) {
    final childDef = definition['child'] as Map<String, dynamic>?;
    final flex = int.tryParse(definition['flex']?.toString() ?? '1') ?? 1;

    return Expanded(
      flex: flex,
      child: childDef != null ? WidgetRegistry.buildWidget(context, childDef, localContext: localContext, path: '$path.child') : const SizedBox.shrink(),
    );
  });

  WidgetRegistry.register('flexible', (context, definition, localContext, path) {
    final childDef = definition['child'] as Map<String, dynamic>?;
    final flex = int.tryParse(definition['flex']?.toString() ?? '1') ?? 1;
    final fitStr = definition['fit']?.toString().toLowerCase();

    return Flexible(
      flex: flex,
      fit: fitStr == 'tight' ? FlexFit.tight : FlexFit.loose,
      child: childDef != null ? WidgetRegistry.buildWidget(context, childDef, localContext: localContext, path: '$path.child') : const SizedBox.shrink(),
    );
  });

  WidgetRegistry.register('spacer', (context, definition, localContext, path) {
    final flex = int.tryParse(definition['flex']?.toString() ?? '1') ?? 1;
    return Spacer(flex: flex);
  });

  WidgetRegistry.register('wrap', (context, definition, localContext, path) {
    final childrenDef = definition['children'] as List<dynamic>? ?? [];
    
    return Wrap(
      spacing: double.tryParse(definition['spacing']?.toString() ?? '0') ?? 0.0,
      runSpacing: double.tryParse(definition['runSpacing']?.toString() ?? '0') ?? 0.0,
      alignment: _parseWrapAlignment(definition['alignment']),
      children: childrenDef.asMap().entries
          .map<Widget>((entry) => WidgetRegistry.buildWidget(context, entry.value as Map<String, dynamic>, localContext: localContext, path: '$path.children.${entry.key}'))
          .toList(),
    );
  });

  WidgetRegistry.register('divider', (context, definition, localContext, path) {
    return Divider(
      color: ConfigParser.parseColor(definition['color']),
      height: double.tryParse(definition['height']?.toString() ?? ''),
      thickness: double.tryParse(definition['thickness']?.toString() ?? ''),
      indent: double.tryParse(definition['indent']?.toString() ?? ''),
      endIndent: double.tryParse(definition['endIndent']?.toString() ?? ''),
    );
  });

  WidgetRegistry.register('safearea', (context, definition, localContext, path) {
    final childDef = definition['child'] as Map<String, dynamic>?;
    return SafeArea(
      child: childDef != null ? WidgetRegistry.buildWidget(context, childDef, localContext: localContext, path: '$path.child') : const SizedBox.shrink(),
    );
  });

  WidgetRegistry.register('scrollview', (context, definition, localContext, path) {
    final childDef = definition['child'] as Map<String, dynamic>?;
    return SingleChildScrollView(
      padding: ConfigParser.parseEdgeInsets(definition['padding'])?.resolve(Directionality.of(context)),
      child: childDef != null ? WidgetRegistry.buildWidget(context, childDef, localContext: localContext, path: '$path.child') : const SizedBox.shrink(),
    );
  });

  WidgetRegistry.register('padding', (context, definition, localContext, path) {
    final childDef = definition['child'] as Map<String, dynamic>?;
    return Padding(
      padding: ConfigParser.parseEdgeInsets(definition['padding'])?.resolve(Directionality.of(context)) ?? EdgeInsets.zero,
      child: childDef != null ? WidgetRegistry.buildWidget(context, childDef, localContext: localContext, path: '$path.child') : const SizedBox.shrink(),
    );
  });

  WidgetRegistry.register('sizedbox', (context, definition, localContext, path) {
    final childDef = definition['child'] as Map<String, dynamic>?;
    return SizedBox(
      width: double.tryParse(definition['width']?.toString() ?? ''),
      height: double.tryParse(definition['height']?.toString() ?? ''),
      child: childDef != null ? WidgetRegistry.buildWidget(context, childDef, localContext: localContext, path: '$path.child') : null,
    );
  });

  WidgetRegistry.register('align', (context, definition, localContext, path) {
    final childDef = definition['child'] as Map<String, dynamic>?;
    return Align(
      alignment: ConfigParser.parseAlignment(definition['alignment']) as Alignment? ?? Alignment.center,
      child: childDef != null ? WidgetRegistry.buildWidget(context, childDef, localContext: localContext, path: '$path.child') : null,
    );
  });

  WidgetRegistry.register('constrainedbox', (context, definition, localContext, path) {
    final childDef = definition['child'] as Map<String, dynamic>?;
    return ConstrainedBox(
      constraints: ConfigParser.parseBoxConstraints(definition['constraints']) ?? const BoxConstraints(),
      child: childDef != null ? WidgetRegistry.buildWidget(context, childDef, localContext: localContext, path: '$path.child') : null,
    );
  });

  WidgetRegistry.register('each', (context, definition, localContext, path) {
    final itemsRaw = definition['items'];
    final items = itemsRaw is String 
        ? (OperationEngine.evaluate(itemsRaw, localContext) as List<dynamic>? ?? [])
        : (itemsRaw as List<dynamic>? ?? []);
        
    final template = definition['template'] as Map<String, dynamic>?;
    if (template == null) return const SizedBox.shrink();

    final iteratorName = definition['iterator']?.toString() ?? 'item';

    final children = items.asMap().entries.map((entry) {
      final itemContext = { ...localContext, iteratorName: entry.value };
      // Note: Template path is tricky since it's repeating, 
      // but in the editor we usually just want to select the template itself.
      return WidgetRegistry.buildWidget(context, template, localContext: itemContext, path: '$path.template');
    }).toList();

    final type = definition['parentType']?.toString() ?? 'column';
    if (type == 'row') {
      return Row(children: children);
    } else if (type == 'wrap') {
      return Wrap(children: children);
    }
    return Column(children: children);
  });

  WidgetRegistry.register('component', (context, definition, localContext, path) {
    final name = definition['name']?.toString();
    if (name == null) return const Text('Error: Component missing "name"');

    final template = ComponentRegistry.get(name);
    if (template == null) return Text('Error: Component "$name" not found');

    // Merge parameters into localContext
    final params = definition['params'] as Map<String, dynamic>? ?? {};
    final componentContext = { ...localContext, ...params };

    return WidgetRegistry.buildWidget(context, template, localContext: componentContext, path: '$path.params');
  });
}

WrapAlignment _parseWrapAlignment(dynamic value) {
  if (value == null) return WrapAlignment.start;
  switch (value.toString().toLowerCase()) {
    case 'center': return WrapAlignment.center;
    case 'end': return WrapAlignment.end;
    case 'spacebetween':
    case 'space_between': return WrapAlignment.spaceBetween;
    case 'spacearound':
    case 'space_around': return WrapAlignment.spaceAround;
    case 'spaceevenly':
    case 'space_evenly': return WrapAlignment.spaceEvenly;
    default: return WrapAlignment.start;
  }
}

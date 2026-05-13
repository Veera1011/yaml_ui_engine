import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../registry/widget_registry.dart';
import '../../../state/app_state.dart';
import '../../../actions/action_engine.dart';
import '../utils/config_parser.dart';

void registerAdvancedWidgets() {
  WidgetRegistry.register('image', (context, definition, localContext, path) {
    final src = definition['src']?.toString();
    if (src == null) return const Text('Error: Image missing "src"');
    
    final width = double.tryParse(definition['width']?.toString() ?? '');
    final height = double.tryParse(definition['height']?.toString() ?? '');

    if (src.startsWith('http')) {
      return Image.network(src, width: width, height: height, fit: BoxFit.cover);
    } else {
      return Image.asset(src, width: width, height: height, fit: BoxFit.cover);
    }
  });

  WidgetRegistry.register('stack', (context, definition, localContext, path) {
    final childrenDef = definition['children'] as List<dynamic>? ?? [];
    return Stack(
      children: childrenDef.asMap().entries
          .map<Widget>((entry) => WidgetRegistry.buildWidget(context, entry.value as Map<String, dynamic>, localContext: localContext, path: '$path.children.${entry.key}'))
          .toList(),
    );
  });

  WidgetRegistry.register('listview', (context, definition, localContext, path) {
    final childrenDef = definition['children'] as List<dynamic>?;
    
    if (childrenDef != null) {
      return ListView(
        shrinkWrap: true,
        children: childrenDef.asMap().entries
            .map<Widget>((entry) => WidgetRegistry.buildWidget(context, entry.value as Map<String, dynamic>, localContext: localContext, path: '$path.children.${entry.key}'))
            .toList(),
      );
    }
    
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(appStateProvider);
        final dataSourceKey = definition['dataSource']?.toString();
        final templateDef = definition['itemTemplate'] as Map<String, dynamic>?;

        if (dataSourceKey == null || templateDef == null) {
           return const Text('Error: ListView missing children or dataSource/itemTemplate');
        }

        final items = state[dataSourceKey] as List<dynamic>? ?? [];
        final iteratorName = definition['iterator']?.toString() ?? 'item';
        
        return ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final itemContext = { ...localContext, iteratorName: items[index] };
            return WidgetRegistry.buildWidget(context, templateDef, localContext: itemContext, path: '$path.itemTemplate');
          },
        );
      },
    );
  });

  WidgetRegistry.register('gridview', (context, definition, localContext, path) {
    final childrenDef = definition['children'] as List<dynamic>? ?? [];
    final crossAxisCount = int.tryParse(definition['crossAxisCount']?.toString() ?? '2') ?? 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      children: childrenDef.asMap().entries
          .map<Widget>((entry) => WidgetRegistry.buildWidget(context, entry.value as Map<String, dynamic>, localContext: localContext, path: '$path.children.${entry.key}'))
          .toList(),
    );
  });

  WidgetRegistry.register('checkbox', (context, definition, localContext, path) {
    return Consumer(
      builder: (context, ref, child) {
        final name = definition['name'] as String?;
        if (name == null) return const Text('Error: Checkbox missing "name"');

        final state = ref.watch(appStateProvider);
        final value = state[name] == true || state[name] == 'true';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
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


  WidgetRegistry.register('tabs', (context, definition, localContext, path) {
    final tabsDef = definition['tabs'] as List<dynamic>? ?? [];
    if (tabsDef.isEmpty) return const Text('Error: Tabs missing "tabs" list');

    return DefaultTabController(
      length: tabsDef.length,
      child: Column(
        children: [
          TabBar(
            labelColor: ConfigParser.parseColor(definition['labelColor']) ?? Colors.blue,
            unselectedLabelColor: ConfigParser.parseColor(definition['unselectedLabelColor']) ?? Colors.grey,
            indicatorColor: ConfigParser.parseColor(definition['indicatorColor']),
            tabs: tabsDef.map<Widget>((tab) {
              return Tab(
                text: tab['title']?.toString() ?? 'Tab',
                icon: tab['icon'] != null ? Icon(ConfigParser.parseIconData(tab['icon'].toString())) : null,
              );
            }).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: tabsDef.asMap().entries.map<Widget>((entry) {
                final tab = entry.value as Map<String, dynamic>;
                final bodyDef = tab['body'] as Map<String, dynamic>?;
                if (bodyDef != null) {
                  return WidgetRegistry.buildWidget(context, bodyDef, localContext: localContext, path: '$path.tabs.${entry.key}.body');
                }
                return const Center(child: Text('Empty Tab Body'));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  });

  WidgetRegistry.register('circleavatar', (context, definition, localContext, path) {
    final src = definition['src']?.toString();
    final radius = double.tryParse(definition['radius']?.toString() ?? '');
    final color = ConfigParser.parseColor(definition['color']);

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      backgroundImage: src != null 
        ? (src.startsWith('http') ? NetworkImage(src) : AssetImage(src) as ImageProvider)
        : null,
      child: definition['child'] != null ? WidgetRegistry.buildWidget(context, definition['child'], localContext: localContext, path: '$path.child') : null,
    );
  });

  WidgetRegistry.register('listtile', (context, definition, localContext, path) {
    return Consumer(
      builder: (context, ref, child) {
        return ListTile(
          leading: definition['leading'] != null ? WidgetRegistry.buildWidget(context, definition['leading'], localContext: localContext, path: '$path.leading') : null,
          title: definition['title'] != null ? WidgetRegistry.buildWidget(context, definition['title'], localContext: localContext, path: '$path.title') : null,
          subtitle: definition['subtitle'] != null ? WidgetRegistry.buildWidget(context, definition['subtitle'], localContext: localContext, path: '$path.subtitle') : null,
          trailing: definition['trailing'] != null ? WidgetRegistry.buildWidget(context, definition['trailing'], localContext: localContext, path: '$path.trailing') : null,
          onTap: () {
            final actionDef = definition['action'];
            if (actionDef != null && actionDef is Map<String, dynamic>) {
               ActionEngine.execute(context, ref, actionDef, contextMap: localContext);
            }
          },
        );
      },
    );
  });
}

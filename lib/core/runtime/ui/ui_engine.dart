import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../registry/widget_registry.dart';
import '../../state/app_state.dart';
import '../../permissions/permission_engine.dart';
import '../../effects/effect_engine.dart';
import '../../parser/yaml_parser.dart';
import '../../actions/action_engine.dart';
import 'package:yaml_ui_engine/core/runtime/ui/widgets/advanced_widgets.dart';
import 'package:yaml_ui_engine/core/runtime/ui/widgets/base_widgets.dart';
import 'package:yaml_ui_engine/core/runtime/ui/widgets/element_widgets.dart';
import 'package:yaml_ui_engine/core/runtime/ui/widgets/layout_widgets.dart';
import 'utils/config_parser.dart';

/// The root widget that builds a UI from a Map definition.
class YamlUiBuilder extends ConsumerStatefulWidget {
  final Map<String, dynamic> definition;

  const YamlUiBuilder({super.key, required this.definition});

  /// Helper to build a UI directly from a raw YAML string.
  factory YamlUiBuilder.fromYaml(String yamlString) {
    return YamlUiBuilder(definition: YamlParser.parse(yamlString));
  }

  @override
  ConsumerState<YamlUiBuilder> createState() => _YamlUiBuilderState();
}

class _YamlUiBuilderState extends ConsumerState<YamlUiBuilder> {
  @override
  void initState() {
    super.initState();
    // 0. Ensure all widgets are registered
    registerBaseWidgets();
    registerLayoutWidgets();
    registerAdvancedWidgets();
    registerElementWidgets();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Initialize State Features (Initial State, Persistence, Computed)
      ref.read(appStateProvider.notifier).initialize(
        initialState: widget.definition['initialState'] as Map<String, dynamic>?,
        persist: widget.definition['persist'] as List<dynamic>?,
        computed: widget.definition['computed'] as Map<dynamic, dynamic>?,
      );

      // 2. Initialize Effects
      if (widget.definition.containsKey('effects')) {
        EffectEngine.setEffects(widget.definition['effects'] as List<dynamic>?);
        ref.read(appStateProvider.notifier).addListener((key, value) {
          if (mounted) {
            EffectEngine.onStateChanged(context, ref, key, value);
          }
        });
      }

      // 3. Trigger onInit Hook
      final onInit = widget.definition['onInit'];
      if (onInit != null) {
        ActionEngine.execute(context, ref, onInit);
      }
    });
  }

  @override
  void dispose() {
    // Trigger onDispose Hook
    // Note: Since we are disposing, we can't show snackbars or navigate, but we can update state/API.
    final onDispose = widget.definition['onDispose'];
    if (onDispose != null) {
      // Logic for background disposal actions
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    // Use a post-frame callback or similar to avoid "build during build" error
    // but for state that only changes on resize, it might be okay or need a microtask.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(appStateProvider.notifier).updateMetrics(
          width: size.width,
          height: size.height,
          orientation: orientation,
        );
      }
    });

    try {
      final state = ref.watch(appStateProvider);

      // Screen-level permission check
      if (!PermissionEngine.hasPermission(widget.definition, state)) {
        return _buildAccessDenied();
      }

      // Determine the root structure. Often a screen definition has a 'body'.
      if (widget.definition.containsKey('type')) {
        return WidgetRegistry.buildWidget(context, widget.definition, path: 'root');
      }

      if (widget.definition.containsKey('body')) {
        return _buildRootScaffold(context, widget.definition);
      }

      return const Center(child: Text('Invalid Screen Definition'));
    } catch (e, stack) {
      return _buildErrorScreen(e, stack);
    }
  }

  Widget _buildAccessDenied() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Access Denied', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('You do not have permission to view this screen.'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Object e, StackTrace stack) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'UI Build Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Retry Build'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRootScaffold(BuildContext context, Map<String, dynamic> definition) {
    final appBarDef = definition['appBar'] as Map<String, dynamic>?;
    final bodyDef = definition['body'] as Map<String, dynamic>?;
    final drawerDef = definition['drawer'] as Map<String, dynamic>?;
    final bottomNavDef = definition['bottomNav'] as Map<String, dynamic>?;
    final railDef = definition['rail'] as Map<String, dynamic>?;
    final fabDef = definition['fab'] as Map<String, dynamic>?;

    Widget bodyWidget = bodyDef != null
        ? WidgetRegistry.buildWidget(context, bodyDef, path: 'body')
        : const Center(child: Text("Empty Body"));

    if (railDef != null) {
      bodyWidget = Row(
        children: [
          _buildNavigationRail(context, railDef),
          Expanded(child: bodyWidget),
        ],
      );
    }

    return Scaffold(
      backgroundColor: ConfigParser.parseColor(definition['backgroundColor']),
      appBar: appBarDef != null ? _buildAppBar(context, appBarDef) : null,
      drawer: drawerDef != null ? _buildDrawer(context, drawerDef) : null,
      bottomNavigationBar: bottomNavDef != null ? _buildBottomNav(context, bottomNavDef) : null,
      floatingActionButton: fabDef != null ? WidgetRegistry.buildWidget(context, fabDef, path: 'fab') : null,
      body: bodyWidget,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Map<String, dynamic> def) {
    return AppBar(
      title: Text(
        def['title']?.toString() ?? '',
        style: ConfigParser.parseTextStyle(def['titleTextStyle']),
      ),
      backgroundColor: ConfigParser.parseColor(def['backgroundColor']),
      elevation: def['elevation'] != null ? double.tryParse(def['elevation'].toString()) : null,
      centerTitle: def['centerTitle'] == true || def['centerTitle'] == 'true',
    );
  }

  Widget _buildDrawer(BuildContext context, Map<String, dynamic> def) {
    final items = def['items'] as List<dynamic>? ?? [];
    final headerDef = def['header'] as Map<String, dynamic>?;
    final bgColor = ConfigParser.parseColor(def['backgroundColor']);

    return Drawer(
      backgroundColor: bgColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (headerDef != null)
            DrawerHeader(
              decoration: BoxDecoration(
                color: ConfigParser.parseColor(headerDef['color']) ?? Theme.of(context).primaryColor,
              ),
              child: headerDef['child'] != null 
                ? WidgetRegistry.buildWidget(context, headerDef['child'], path: 'drawer.header.child') 
                : Text(headerDef['title']?.toString() ?? 'Header'),
            ),
          ...items.map((item) {
            final title = item['title']?.toString() ?? '';
            final route = item['route']?.toString();
            final iconStr = item['icon']?.toString();
            return ListTile(
              leading: iconStr != null ? Icon(ConfigParser.parseIconData(iconStr)) : null,
              title: Text(title),
              onTap: () {
                Navigator.pop(context); // close drawer
                if (route != null) {
                  Navigator.pushNamed(context, route);
                }
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, Map<String, dynamic> def) {
    final items = def['items'] as List<dynamic>? ?? [];
    final bgColor = ConfigParser.parseColor(def['backgroundColor']);
    final selectedColor = ConfigParser.parseColor(def['selectedColor']);
    final unselectedColor = ConfigParser.parseColor(def['unselectedColor']);
    final typeStr = def['type']?.toString().toLowerCase();

    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(appStateProvider);
        final stateKey = '${def['id'] ?? 'bottom_nav'}_index';
        final currentIndex = int.tryParse(state[stateKey]?.toString() ?? def['selectedIndex']?.toString() ?? '0') ?? 0;

        return BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: bgColor,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          type: typeStr == 'fixed' ? BottomNavigationBarType.fixed : BottomNavigationBarType.shifting,
          items: items.map((item) {
            final label = item['label']?.toString() ?? '';
            final iconStr = item['icon']?.toString();
            return BottomNavigationBarItem(
              icon: Icon(ConfigParser.parseIconData(iconStr) ?? Icons.circle),
              label: label,
            );
          }).toList(),
          onTap: (index) {
            ref.read(appStateProvider.notifier).setValue(stateKey, index);
            final route = items[index]['route']?.toString();
            if (route != null) {
              Navigator.pushNamed(context, route);
            }
          },
        );
      },
    );
  }

  Widget _buildNavigationRail(BuildContext context, Map<String, dynamic> def) {
    final items = def['items'] as List<dynamic>? ?? [];
    final bgColor = ConfigParser.parseColor(def['backgroundColor']);
    final selectedColor = ConfigParser.parseColor(def['selectedColor']);
    final unselectedColor = ConfigParser.parseColor(def['unselectedColor']);

    return NavigationRail(
      backgroundColor: bgColor,
      selectedIconTheme: IconThemeData(color: selectedColor),
      unselectedIconTheme: IconThemeData(color: unselectedColor),
      selectedLabelTextStyle: TextStyle(color: selectedColor),
      unselectedLabelTextStyle: TextStyle(color: unselectedColor),
      destinations: items.map((item) {
        final label = item['label']?.toString() ?? '';
        final iconStr = item['icon']?.toString();
        return NavigationRailDestination(
          icon: Icon(ConfigParser.parseIconData(iconStr) ?? Icons.circle),
          label: Text(label),
        );
      }).toList(),
      selectedIndex: int.tryParse(def['selectedIndex']?.toString() ?? '0') ?? 0,
      onDestinationSelected: (index) {
        final route = items[index]['route']?.toString();
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/logic_engine.dart';
import '../permissions/permission_engine.dart';
import '../state/app_state.dart';
import '../focus/focus_engine.dart';
import '../../editor/ui/editable_wrapper.dart';

/// A function type for building a widget from a JSON definition.
typedef DynamicWidgetBuilder = Widget Function(
  BuildContext context,
  Map<String, dynamic> definition,
  Map<String, dynamic> localContext,
  String path,
);

class WidgetRegistry {
  static final Map<String, DynamicWidgetBuilder> _registry = {};
  static bool isEditorMode = false;
  static bool _initialized = false;

  /// Initializes the registry with all built-in widgets.
  static void init() {
    if (_initialized) return;
    // We import these at runtime to avoid circular dependencies if possible, 
    // but here we can just use the provided registration functions.
    _initialized = true;
  }

  /// Registers a new widget builder for a given type.
  static void register(String type, DynamicWidgetBuilder builder) {
    _registry[type] = builder;
  }

  /// Retrieves a widget builder for a given type.
  static DynamicWidgetBuilder? getBuilder(String type) {
    return _registry[type];
  }

  /// Builds a widget for the given definition, returning a default error widget
  /// if the type is unknown or missing.
  /// Builds a widget for the given definition.
  static Widget buildWidget(BuildContext context, Map<String, dynamic> definition, {Map<String, dynamic>? localContext, String path = 'root'}) {
    final type = definition['type'] as String?;
    if (type == null) {
      return const Text('Error: Missing "type" in definition');
    }

    final builder = getBuilder(type);
    if (builder == null) {
      return Text('Error: Unknown widget type "$type"');
    }

    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(appStateProvider);
        final combinedContext = {...state, ...?localContext};
        
        // 1. Check Role Permission
        if (!PermissionEngine.hasPermission(definition, combinedContext)) {
          return const SizedBox.shrink();
        }

        // 2. Check Logic Condition
        if (!LogicEngine.isVisible(definition, combinedContext)) {
          return const SizedBox.shrink();
        }

        // 3. Build Widget
        final builderResult = builder(context, definition, combinedContext, path);
        Widget finalWidget = builderResult;

        if (!LogicEngine.isEnabled(definition, combinedContext)) {
           finalWidget = IgnorePointer(
             ignoring: true,
             child: Opacity(
               opacity: 0.5,
               child: finalWidget,
             ),
           );
        }

        // 4. Basic Animation Wrapper
        final animType = definition['animation']?.toString().toLowerCase();
        Widget result;
        if (animType == 'fade') {
          result = _FadeInWidget(child: finalWidget);
        } else if (animType == 'scale') {
          result = _ScaleInWidget(child: finalWidget);
        } else {
          result = finalWidget;
        }

        // 5. ID & Key Integration
        final id = definition['id']?.toString();
        if (id != null) {
          return KeyedSubtree(
            key: FocusEngine.getOrCreateKey(id),
            child: result,
          );
        }
        
        if (isEditorMode) {
          return EditableWrapper(
            path: path,
            definition: definition,
            child: result,
          );
        }
        
        return result;
      },
    );
  }
}

class _FadeInWidget extends StatefulWidget {
  final Widget child;
  const _FadeInWidget({required this.child});
  @override
  State<_FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<_FadeInWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _animation, child: widget.child);
}

class _ScaleInWidget extends StatefulWidget {
  final Widget child;
  const _ScaleInWidget({required this.child});
  @override
  State<_ScaleInWidget> createState() => _ScaleInWidgetState();
}

class _ScaleInWidgetState extends State<_ScaleInWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _animation, child: widget.child);
}

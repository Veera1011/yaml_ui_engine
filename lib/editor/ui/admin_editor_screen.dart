import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/parser/yaml_parser.dart';
import '../state/editor_state.dart';
import '../../core/registry/widget_registry.dart';
import '../../core/runtime/ui/ui_engine.dart';
import 'palette_panel.dart';
import 'property_inspector.dart';

class AdminEditorScreen extends ConsumerStatefulWidget {
  const AdminEditorScreen({super.key});

  @override
  ConsumerState<AdminEditorScreen> createState() => _AdminEditorScreenState();
}

class _AdminEditorScreenState extends ConsumerState<AdminEditorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetRegistry.isEditorMode = true;
  }

  @override
  void dispose() {
    WidgetRegistry.isEditorMode = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('YAML Admin Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => ref.read(editorStateProvider.notifier).undo(),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy YAML',
            onPressed: () {
              final yaml = YamlParser.toYaml(editorState.definition);
              Clipboard.setData(ClipboardData(text: yaml));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('YAML copied to clipboard!')),
              );
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Preview'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog.fullscreen(
                  child: Scaffold(
                    appBar: AppBar(title: const Text('Live Preview')),
                    body: YamlUiBuilder(definition: editorState.definition),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left: Palette
          const SizedBox(
            width: 250,
            child: PalettePanel(),
          ),
          const VerticalDivider(width: 1),
          
          // Center: Canvas
          Expanded(
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Container(
                  width: 375, // Mobile width preview
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: YamlUiBuilder(definition: editorState.definition),
                ),
              ),
            ),
          ),
          
          const VerticalDivider(width: 1),
          
          // Right: Property Inspector
          const SizedBox(
            width: 300,
            child: PropertyInspector(),
          ),
        ],
      ),
    );
  }
}

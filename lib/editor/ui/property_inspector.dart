import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/editor_state.dart';

class PropertyInspector extends ConsumerWidget {
  const PropertyInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final path = editorState.selectedPath;

    if (path == null) {
      return const Center(
        child: Text('Select a widget to edit its properties'),
      );
    }

    final definition = ref.read(editorStateProvider.notifier).getDefinitionAtPath(path);
    if (definition == null) return const Text('Error: Definition not found');
    
    final type = definition['type']?.toString() ?? 'unknown';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inspector: $type', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(path, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          const Divider(),
          const SizedBox(height: 16),
          
          if (definition.containsKey('value') || definition.containsKey('text')) ...[
            const Text('Text Content', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('$path-value'), // Force rebuild on selection change
              initialValue: (definition['value'] ?? definition['text'])?.toString(),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onFieldSubmitted: (val) {
                final key = definition.containsKey('value') ? 'value' : 'text';
                ref.read(editorStateProvider.notifier).updateWidgetProperty(path, key, val);
              },
            ),
          ],
          
          const SizedBox(height: 16),
          
          if (definition.containsKey('label')) ...[
            const SizedBox(height: 16),
            const Text('Label', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('$path-label'),
              initialValue: definition['label']?.toString(),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onFieldSubmitted: (val) => ref.read(editorStateProvider.notifier).updateWidgetProperty(path, 'label', val),
            ),
          ],
          
          if (definition.containsKey('color')) ...[
            const SizedBox(height: 16),
            const Text('Color (Hex)', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('$path-color'),
              initialValue: definition['color']?.toString(),
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '#RRGGBB'),
              onFieldSubmitted: (val) => ref.read(editorStateProvider.notifier).updateWidgetProperty(path, 'color', val),
            ),
          ],

          if (definition.containsKey('width') || definition.containsKey('height')) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (definition.containsKey('width')) Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Width', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: ValueKey('$path-width'),
                        initialValue: definition['width']?.toString(),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        onFieldSubmitted: (val) => ref.read(editorStateProvider.notifier).updateWidgetProperty(path, 'width', val),
                      ),
                    ],
                  ),
                ),
                if (definition.containsKey('width') && definition.containsKey('height')) const SizedBox(width: 16),
                if (definition.containsKey('height')) Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Height', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: ValueKey('$path-height'),
                        initialValue: definition['height']?.toString(),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        onFieldSubmitted: (val) => ref.read(editorStateProvider.notifier).updateWidgetProperty(path, 'height', val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
            ),
            onPressed: () {
              ref.read(editorStateProvider.notifier).deleteWidget(path);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.delete_outline), SizedBox(width: 8), Text('Delete Widget')],
            ),
          ),
        ],
      ),
    );
  }
}

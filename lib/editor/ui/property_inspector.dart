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
          
          // Add more property editors based on type...

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

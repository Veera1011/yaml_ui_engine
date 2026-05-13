import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/editor_state.dart';

class PalettePanel extends ConsumerWidget {
  const PalettePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgets = [
      {'name': 'Text', 'icon': Icons.text_fields, 'def': {'type': 'text', 'value': 'New Text'}},
      {'name': 'Button', 'icon': Icons.smart_button, 'def': {'type': 'button', 'text': 'Click Me'}},
      {'name': 'Image', 'icon': Icons.image, 'def': {'type': 'image', 'src': 'https://via.placeholder.com/150'}},
      {'name': 'TextField', 'icon': Icons.input, 'def': {'type': 'textfield', 'name': 'field', 'label': 'Input'}},
      {'name': 'Column', 'icon': Icons.view_column, 'def': {'type': 'column', 'children': []}},
      {'name': 'Row', 'icon': Icons.view_headline, 'def': {'type': 'row', 'children': []}},
      {'name': 'Card', 'icon': Icons.credit_card, 'def': {'type': 'card', 'child': {'type': 'text', 'value': 'Card Content'}}},
    ];

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Widget Palette', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: widgets.length,
              itemBuilder: (context, index) {
                final w = widgets[index];
                return ListTile(
                  leading: Icon(w['icon'] as IconData),
                  title: Text(w['name'] as String),
                  onTap: () {
                    // For now, just add to body children
                    ref.read(editorStateProvider.notifier).addWidget('body.children', w['def'] as Map<String, dynamic>);
                  },
                  trailing: const Icon(Icons.add_circle_outline, size: 20),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

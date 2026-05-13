import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/editor_state.dart';

class EditableWrapper extends ConsumerWidget {
  final Widget child;
  final String path;
  final Map<String, dynamic> definition;

  const EditableWrapper({
    super.key,
    required this.child,
    required this.path,
    required this.definition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final isSelected = editorState.selectedPath == path;

    return GestureDetector(
      onTap: () {
        ref.read(editorStateProvider.notifier).selectWidget(path);
      },
      child: Container(
        decoration: BoxDecoration(
          border: isSelected 
              ? Border.all(color: Colors.blue, width: 2) 
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Stack(
          children: [
            child,
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  color: Colors.blue,
                  child: const Icon(Icons.edit, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

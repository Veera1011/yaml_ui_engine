import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditorState {
  final Map<String, dynamic> definition;
  final String? selectedPath;
  final List<Map<String, dynamic>> history;

  EditorState({
    required this.definition,
    this.selectedPath,
    this.history = const [],
  });

  EditorState copyWith({
    Map<String, dynamic>? definition,
    String? selectedPath,
    List<Map<String, dynamic>>? history,
  }) {
    return EditorState(
      definition: definition ?? this.definition,
      selectedPath: selectedPath ?? this.selectedPath,
      history: history ?? this.history,
    );
  }
}

class EditorStateNotifier extends Notifier<EditorState> {
  @override
  EditorState build() {
    return EditorState(definition: {
      'appBar': {'title': 'New Screen'},
      'body': {'type': 'column', 'children': []}
    });
  }

  /// Gets the definition at a specific path.
  Map<String, dynamic>? getDefinitionAtPath(String path) {
    dynamic current = state.definition;
    for (final part in path.split('.')) {
      if (current is Map) {
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part);
        if (index != null && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current is Map<String, dynamic> ? current : null;
  }

  /// Updates the definition and saves to history.
  void updateDefinition(Map<String, dynamic> newDefinition) {
    final newHistory = [...state.history, state.definition];
    state = state.copyWith(
      definition: newDefinition,
      history: newHistory,
    );
  }

  /// Selects a widget by its path (e.g., "body.children.0").
  void selectWidget(String? path) {
    state = state.copyWith(selectedPath: path);
  }

  /// Adds a child widget to a parent list.
  void addWidget(String? parentPath, Map<String, dynamic> widgetDef) {
    final newDef = Map<String, dynamic>.from(state.definition);
    final targetPath = parentPath ?? 'body.children';
    
    _updateDeep(newDef, targetPath.split('.'), (node) {
      if (node is List) {
        node.add(widgetDef);
      } else if (node is Map<String, dynamic> && node.containsKey('children')) {
        final children = List<dynamic>.from(node['children'] ?? []);
        children.add(widgetDef);
        node['children'] = children;
      } else if (node is Map<String, dynamic> && node.containsKey('child')) {
        node['child'] = widgetDef;
      }
    });
    
    updateDefinition(newDef);
  }

  /// Updates a property at a specific path.
  void updateWidgetProperty(String path, String property, dynamic value) {
    final newDef = Map<String, dynamic>.from(state.definition);
    _updateDeep(newDef, path.split('.'), (node) {
      if (node is Map<String, dynamic>) {
        node[property] = value;
      }
    });
    updateDefinition(newDef);
  }

  /// Deletes a widget at a specific path.
  void deleteWidget(String path) {
    final newDef = Map<String, dynamic>.from(state.definition);
    final parts = path.split('.');
    final last = parts.removeLast();
    
    _updateDeep(newDef, parts, (node) {
      if (node is Map<String, dynamic>) {
        node.remove(last);
      } else if (node is List) {
        final index = int.tryParse(last);
        if (index != null && index < node.length) node.removeAt(index);
      }
    });
    
    state = state.copyWith(selectedPath: null);
    updateDefinition(newDef);
  }

  void _updateDeep(dynamic node, List<String> parts, Function(dynamic) updater) {
    if (parts.isEmpty) {
      updater(node);
      return;
    }

    final key = parts.removeAt(0);
    if (node is Map<String, dynamic>) {
      if (parts.isEmpty) {
        updater(node[key]);
      } else {
        _updateDeep(node[key], parts, updater);
      }
    } else if (node is List) {
      final index = int.tryParse(key);
      if (index != null && index < node.length) {
        if (parts.isEmpty) {
          updater(node[index]);
        } else {
          _updateDeep(node[index], parts, updater);
        }
      }
    }
  }

  /// Undo last change.
  void undo() {
    if (state.history.isNotEmpty) {
      final last = state.history.last;
      final newHistory = state.history.sublist(0, state.history.length - 1);
      state = state.copyWith(
        definition: last,
        history: newHistory,
      );
    }
  }
}

final editorStateProvider = NotifierProvider<EditorStateNotifier, EditorState>(() {
  return EditorStateNotifier();
});

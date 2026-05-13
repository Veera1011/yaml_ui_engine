import 'package:flutter/widgets.dart';

class FocusEngine {
  static final Map<String, FocusNode> _focusNodes = {};
  static final Map<String, GlobalKey> _scrollKeys = {};

  /// Gets or creates a FocusNode for a specific widget ID.
  static FocusNode getOrCreateNode(String id) {
    return _focusNodes.putIfAbsent(id, () => FocusNode());
  }

  /// Gets or creates a GlobalKey for a specific widget ID (used for scrolling).
  static GlobalKey getOrCreateKey(String id) {
    return _scrollKeys.putIfAbsent(id, () => GlobalKey());
  }

  /// Requests focus for a specific widget ID.
  static void focus(String id) {
    _focusNodes[id]?.requestFocus();
  }

  /// Scrolls to a specific widget ID.
  static void scrollTo(String id) {
    final context = _scrollKeys[id]?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Cleans up nodes (call on screen dispose).
  static void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
    _scrollKeys.clear();
  }
}

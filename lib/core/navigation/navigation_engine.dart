import 'package:flutter/material.dart';

class NavigationEngine {
  /// Navigates to a specific route.
  static void navigate(BuildContext context, String route, {bool replace = false}) {
    if (replace) {
      Navigator.of(context).pushReplacementNamed(route);
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }

  /// Pops the current route.
  static void pop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

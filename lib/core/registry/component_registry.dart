class ComponentRegistry {
  static final Map<String, Map<String, dynamic>> _components = {};

  /// Registers a reusable component definition.
  static void register(String name, Map<String, dynamic> definition) {
    _components[name] = definition;
  }

  /// Gets a registered component.
  static Map<String, dynamic>? get(String name) {
    return _components[name];
  }

  /// Checks if a component exists.
  static bool exists(String name) {
    return _components.containsKey(name);
  }

  /// Clears the registry.
  static void clear() {
    _components.clear();
  }
}

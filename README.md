# YAML Flutter Engine

A production-grade, enterprise-ready runtime engine that renders Flutter UIs and handles complex business logic directly from YAML/JSON configurations.

## Features

- 🚀 **Dynamic UI**: Build full screens without writing Dart code.
- 🧠 **Smart Logic**: Built-in expression evaluator for dynamic properties and visibility.
- 🔄 **Workflow Engine**: Execute multi-step actions (API calls, navigation, state updates).
- 💾 **State Persistence**: Automatic local storage for important application state.
- 📱 **Native Responsiveness**: Real-time device metrics for adaptive layouts.
- 🧩 **Reusable Components**: Global registry for modular UI templates.
- 🛠️ **Visual Admin Editor**: Drag-and-drop interface to build screens visually.

---

## 🚀 Getting Started

### 1. Requirements
Ensure your `pubspec.yaml` has the necessary dependencies:
```yaml
dependencies:
  flutter_riverpod: ^3.3.1
  yaml_ui_engine: # current path
```

### 2. Basic Implementation
Wrap your app in a `ProviderScope` and use the `YamlUiBuilder`.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaml_ui_engine/yaml_ui_engine.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: YamlUiBuilder.fromYaml('''
        appBar:
          title: Welcome App
        body:
          type: column
          children:
            - type: text
              value: "Hello World!"
      '''),
    );
  }
}
```

---

## 📝 Configuration Schema

### Core Screen Structure
| Key | Type | Description |
|-----|------|-------------|
| `initialState` | Map | Initial values for global app state. |
| `persist` | List | Keys that should be saved to local storage. |
| `onInit` | Map | Action to execute when the screen loads. |
| `appBar` | Map | Definition for the screen's AppBar. |
| `body` | Map | The main UI widget (e.g., column, listview). |

### Common Widgets
- **`text`**: Standard label. Supports `value`, `style`, `textAlign`.
- **`button`**: Interactive button. Supports `text`, `color`, `action`.
- **`textfield`**: User input. Supports `name` (state key), `label`, `validation`.
- **`image`**: Network or Asset images. Supports `src`, `width`, `height`.
- **`column` / `row`**: Layout containers for `children`.
- **`container`**: Styled box with `margin`, `padding`, `decoration`.

---

## 💡 Pro Tip: Inline Syntax (JSON-Style)
YAML is a superset of JSON. For small widgets or nested properties, you can use compact inline syntax to keep your configurations concise:

**Standard:**
```yaml
appBar:
  title: My App
  centerTitle: true
```

**Inline:**
```yaml
appBar: { title: "My App", centerTitle: true }
```

Both are valid and can be mixed throughout your screens.

---

## 💡 Dynamic Logic & Expressions

Use double curly braces `{{ }}` to inject state or perform calculations.

### Interactivity
```yaml
- type: text
  value: "Hello {{username}}!"
  visibleIf: "{{isAdmin == true}}"
```

### Rule Engine
Control field behavior dynamically:
- `hiddenIf`: Hide widget based on state.
- `disabledIf`: Disable inputs based on conditions.
- `requiredIf`: Force validation only when a condition is met.

---

## 🛠️ Workflows & Actions

Actions can be attached to `onTap`, `onInit`, or form submissions.

### Multi-step Workflow
```yaml
action:
  type: sequence
  steps:
    - type: api
      url: "https://api.example.com/login"
      method: POST
      body: { "user": "{{username}}" }
      onSuccess:
        type: navigate
        route: "/home"
    - type: setState
      key: "isLoggedIn"
      value: true
```

### Supported Action Types:
- `api`: HTTP requests (GET, POST, etc.).
- `navigate`: Route navigation.
- `setState`: Update global app state.
- `focus`: Programmatically focus a text field.
- `scrollTo`: Scroll to a specific widget ID.
- `snack`: Show a notification message.

---

## 📱 Responsive Design

The engine injects a global `device` object into the state:
- `device.width` / `device.height`
- `device.isMobile` / `device.isTablet` / `device.isDesktop`
- `device.orientation` (portrait/landscape)

**Usage:**
```yaml
type: container
width: "{{device.isMobile ? 100 : 400}}"
```

---

## 🧩 Global Components

Register reusable UI blocks to keep your YAML DRY.

**Registration:**
```dart
ComponentRegistry.register('user_card', {
  'type': 'card',
  'child': { 'type': 'text', 'value': 'User: {{name}}' }
});
```

**Usage in YAML:**
```yaml
type: component
name: user_card
params:
  name: "Veera"
```

---

## 🎨 Visual Admin Editor Guide

The `AdminEditorScreen` is a built-in IDE for your YAML screens. It allows you to build, test, and export UIs visually.

### How to Launch
Integrate the editor into your dev menu or a dedicated route:

```dart
ElevatedButton(
  onPressed: () => Navigator.push(
    context, 
    MaterialPageRoute(builder: (_) => const AdminEditorScreen())
  ),
  child: const Text('Open Visual Editor'),
)
```

### Key Workflow
1.  **Widget Palette (Left)**: Click any widget to add it to the `body` of your screen. 
2.  **Live Canvas (Center)**: 
    *   The canvas renders your YAML definition in real-time.
    *   **Select**: Click any widget on the canvas to highlight it.
    *   **Blue Border**: Indicates the currently selected widget.
3.  **Property Inspector (Right)**:
    *   Edit the `value` or `text` of the selected widget.
    *   Changes are reflected instantly on the canvas.
    *   **Delete**: Remove the selected widget from the tree.
4.  **Preview Mode**: Click the **Preview** button in the top bar to test the screen's full interactivity in a mobile-sized dialog.
5.  **Exporting**: Click the **Copy** (Clipboard) icon in the top bar. This generates the full YAML string and copies it to your clipboard.

---

## 🔒 Permissions

Secure your UI based on user roles or permissions.

```yaml
type: button
text: "Delete Record"
requiredRoles: ["admin"]
permissionCondition: "{{user.canDelete == true}}"
```

---

## 📚 Library of Examples

Ready-to-use YAML templates for common application scenarios.

### 1. Login Screen (With Validation & API)
Demonstrates: Forms, TextFields, Validation, Sequence Actions, and API calls.

```yaml
appBar:
  title: Login
body:
  type: padding
  padding: 24
  child:
    type: column
    mainAxisAlignment: center
    children:
      - type: text
        value: "Welcome Back"
        style: { fontSize: 28, fontWeight: bold }
      - type: sizedbox
        height: 32
      - type: form
        name: login_form
        child:
          type: column
          children:
            - type: textfield
              name: email
              label: Email Address
              validation: { type: email, required: true }
            - type: textfield
              name: password
              label: Password
              obscureText: true
              validation: { minLength: 6, required: true }
            - type: sizedbox
              height: 24
            - type: button
              text: Login
              color: "#2196F3"
              textColor: "#FFFFFF"
              action:
                type: sequence
                steps:
                  - type: api
                    url: "https://auth.example.com/login"
                    method: POST
                    body: { "user": "{{email}}", "pass": "{{password}}" }
                    onSuccess:
                      type: navigate
                      route: "/dashboard"
                    onError:
                      type: snack
                      message: "Login Failed: {{error}}"
```

---

### 2. Responsive Dashboard
Demonstrates: GridView, Device Metrics, and Conditional Styling.

```yaml
initialState:
  stats:
    - { title: "Users", count: 1240, color: "#4CAF50" }
    - { title: "Revenue", count: "$5.2k", color: "#2196F3" }
    - { title: "Orders", count: 86, color: "#FF9800" }
    - { title: "Alerts", count: 3, color: "#F44336" }
appBar:
  title: "Admin Panel ({{device.isMobile ? 'Mobile' : 'Desktop'}})"
body:
  type: scrollview
  child:
    type: padding
    padding: 16
    child:
      type: column
      children:
        - type: text
          value: Dashboard Overview
        - type: gridview
          crossAxisCount: "{{device.isMobile ? 2 : 4}}"
          children:
            - type: each
              items: "{{stats}}"
              template:
                type: card
                color: "{{item.color}}"
                child:
                  type: column
                  children:
                    - type: text
                      value: "{{item.title}}"
                    - type: text
                      value: "{{item.count}}"
```

---

### 3. Product List with Search
Demonstrates: Dynamic Filtering, ListView, and State Updates.

```yaml
initialState:
  searchQuery: ""
  products:
    - { name: "iPhone 15", price: 999 }
    - { name: "MacBook Air", price: 1299 }
appBar:
  title: Product Store
body:
  type: column
  children:
    - type: textfield
      name: searchQuery
      label: Search Products...
    - type: listview
      children:
        - type: each
          items: "{{products}}"
          template:
            type: listtile
            visibleIf: "{{searchQuery == '' || contains(lower(item.name), lower(searchQuery))}}"
            title: { type: text, value: "{{item.name}}" }
```

---

### 4. Conditional "Work Order" Form
Demonstrates: `hiddenIf`, `disabledIf`, and deep logic.

```yaml
initialState:
  orderType: "Standard"
body:
  type: column
  children:
    - type: dropdown
      name: orderType
      options: ["Standard", "Urgent", "Emergency"]
    - type: textfield
      name: reason
      label: Reason for Urgency
      hiddenIf: "{{orderType == 'Standard'}}"
```

---

### 5. Tabbed Profile Screen
Demonstrates: Tabs, CircleAvatar, and Layouts.

```yaml
body:
  type: tabs
  tabs:
    - title: Overview
      icon: person
      body:
        type: column
        children:
          - type: circleavatar
            src: "https://i.pravatar.cc/300"
          - type: text
            value: "John Doe"
```

---

### 6. Advanced API Error Handling
```yaml
action:
  type: sequence
  steps:
    - type: setState
      key: "isLoading"
      value: true
    - type: api
      url: "https://api.example.com/sync"
      onSuccess:
        type: snack
        message: "Sync Successful!"
      onError:
        type: setState
        key: "errorMessage"
        value: "{{error}}"
```

---

### 7. The Super App (All-in-One)
```yaml
appBar: { title: "Super App" }
drawer: { header: { title: "Menu" }, items: [{ title: "Home", icon: home }] }
bottomNav: { items: [{ label: "Home", icon: home }] }
body:
  type: tabs
  tabs:
    - title: "Home"
      body: { type: text, value: "Home Page" }
```

---

### 8. Side-Effects (EffectEngine)
```yaml
effects:
  - key: "counter"
    condition: "{{counter >= 10}}"
    action:
      type: snack
      message: "Goal Reached!"
```

---

### 9. Role-Based Access Control
```yaml
children:
  - type: button
    requiredRoles: ["admin"]
    text: "Delete Data"
```

---

## 🧪 Testing

The engine comes with a robust test suite. Run it via:
```bash
flutter test
```
All core logic, validation, and layout engines are verified for 100% reliability.

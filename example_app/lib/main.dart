import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaml_ui_engine/yaml_ui_engine.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YAML UI Engine Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DemoHomeScreen(),
        '/editor': (context) => const AdminEditorScreen(),
      },
    );
  }
}

class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({super.key});

  static const String demoYaml = '''
initialState:
  username: "Veeramnikandan"
  cartCount: 5
  isSyncing: false

backgroundColor: "#F5F5F5"

# 1. Top Navigation
appBar:
  title: "Vzha Super App"
  backgroundColor: "#2196F3"
  elevation: 4
  centerTitle: true

# 2. Side Navigation
drawer:
  backgroundColor: "#FFFFFF"
  header:
    color: "#1976D2"
    child:
      type: column
      children:
        - type: circleavatar
          radius: 30
          src: "https://i.pravatar.cc/150"
        - type: sizedbox
          height: 8
        - type: text
          value: "{{username}}"
          style: { color: "#FFFFFF", fontWeight: bold }
  items:
    - title: "Home"
      icon: home
      route: "/"
    - title: "Admin Editor"
      icon: edit
      route: "/editor"
    - title: "Logout"
      icon: logout

# 3. Bottom Navigation
bottomNav:
  backgroundColor: "#FFFFFF"
  selectedColor: "#2196F3"
  items:
    - label: "Explore"
      icon: explore
    - label: "Orders"
      icon: shopping_cart
    - label: "Account"
      icon: person

# 4. Floating Action
fab:
  type: button
  text: "+"
  color: "#FF4081"
  action:
    type: snack
    message: "Create New Item"

# 5. Main Content (With Tabs)
body:
  type: tabs
  labelColor: "#2196F3"
  tabs:
    - title: "Activity"
      icon: history
      body:
        type: listview
        children:
          - type: listtile
            title: { type: text, value: "Order #1234" }
            subtitle: { type: text, value: "Status: Delivered" }
            trailing: { type: icon, icon: check_circle, color: "#4CAF50" }
          - type: listtile
            title: { type: text, value: "Payment Received" }
            subtitle: { type: text, value: "\$50.00 from Client" }
    
    - title: "Stats"
      icon: bar_chart
      body:
        type: padding
        padding: 20
        child:
          type: column
          children:
            - type: text
              value: "Monthly Growth"
              style: { fontSize: 18, fontWeight: bold }
            - type: sizedbox
              height: 20
            - type: row
              mainAxisAlignment: spaceEvenly
              children:
                - type: column
                  children:
                    - type: text
                      value: "85%"
                      style: { fontSize: 24, color: "#4CAF50" }
                    - type: text
                      value: "Retention"
                - type: column
                  children:
                    - type: text
                      value: "12k"
                      style: { fontSize: 24, color: "#2196F3" }
                    - type: text
                      value: "Views"
''';

  @override
  Widget build(BuildContext context) {
    final definition = YamlParser.parse(demoYaml);
    return YamlUiBuilder(definition: definition);
  }
}

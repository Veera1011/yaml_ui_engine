import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:yaml_ui_engine/yaml_ui_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  setUpAll(() {
    registerBaseWidgets();
    registerLayoutWidgets();
    registerAdvancedWidgets();
    registerElementWidgets();
  });

  test('JsonParser converts JSON to Map correctly', () {
    const jsonStr = '''
{
  "screen": "dashboard",
  "appBar": {
    "title": "Dashboard"
  },
  "body": {
    "type": "column",
    "children": [
      {
        "type": "text",
        "value": "Welcome {{username}}"
      }
    ]
  }
}
''';

    final result = JsonParser.parse(jsonStr);
    expect(result['screen'], 'dashboard');
    expect(result['appBar']['title'], 'Dashboard');
    expect(result['body']['type'], 'column');
    expect(result['body']['children'][0]['type'], 'text');
    expect(result['body']['children'][0]['value'], 'Welcome {{username}}');
  });

  test('JsonParser handles lists correctly', () {
    const jsonStr = '[{"id": 1}, {"id": 2}]';
    final result = JsonParser.parse(jsonStr);
    expect(result['items'], isList);
    expect(result['items'].length, 2);
    expect(result['items'][0]['id'], 1);
  });

  testWidgets('YamlUiBuilder.fromJson renders JSON UI correctly', (WidgetTester tester) async {
    const jsonStr = '''
{
  "body": {
    "type": "text",
    "value": "Hello from JSON"
  }
}
''';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: YamlUiBuilder.fromJson(jsonStr),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Hello from JSON'), findsOneWidget);
  });

  testWidgets('YamlUiBuilder.fromString detects JSON correctly', (WidgetTester tester) async {
    const jsonStr = '{"body": {"type": "text", "value": "Detected JSON"}}';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: YamlUiBuilder.fromString(jsonStr),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Detected JSON'), findsOneWidget);
  });

  testWidgets('YamlUiBuilder.fromString detects YAML correctly', (WidgetTester tester) async {
    const yamlStr = 'body:\n  type: text\n  value: Detected YAML';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: YamlUiBuilder.fromString(yamlStr),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Detected YAML'), findsOneWidget);
  });
}

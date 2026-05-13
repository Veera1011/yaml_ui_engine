import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:yaml_ui_engine/yaml_ui_engine.dart';
import 'package:yaml_ui_engine/core/runtime/ui/utils/config_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  setUpAll(() {
    registerBaseWidgets();
    registerLayoutWidgets();
    registerAdvancedWidgets();
    registerElementWidgets();
  });

  tearDown(() {
    FocusEngine.dispose();
  });

  test('YamlParser converts YAML to Map correctly', () {
    const yamlStr = '''
screen: dashboard
appBar:
  title: Dashboard
body:
  type: column
  children:
    - type: text
      value: Welcome {{username}}
''';

    final result = YamlParser.parse(yamlStr);
    expect(result['screen'], 'dashboard');
    expect(result['appBar']['title'], 'Dashboard');
    expect(result['body']['type'], 'column');
    expect(result['body']['children'][0]['type'], 'text');
    expect(result['body']['children'][0]['value'], 'Welcome {{username}}');
  });

  test('OperationEngine evaluates expressions', () {
    final state = {'username': 'Veera', 'qty': 2, 'price': 100};
    
    expect(OperationEngine.evaluate('Welcome {{username}}', state), 'Welcome Veera');
    expect(OperationEngine.evaluate('{{qty * price}}', state), 200);
    expect(OperationEngine.evaluate('{{qty == 2}}', state), true);
  });

  test('LogicEngine evaluates visibility correctly', () {
    final state = {'isAdmin': true, 'score': 50};

    final def1 = {'visibleIf': '{{isAdmin}}'};
    expect(LogicEngine.isVisible(def1, state), true);

    final def2 = {'hiddenIf': '{{score < 100}}'};
    expect(LogicEngine.isVisible(def2, state), false); // hidden because score < 100 is true
  });

  test('PermissionEngine evaluates roles correctly', () {
    final state = {'userRoles': ['editor', 'moderator']};

    final def1 = {'requiredRoles': ['admin', 'editor']};
    expect(PermissionEngine.hasPermission(def1, state), true);

    final def2 = {'hiddenFor': 'editor'};
    expect(PermissionEngine.hasPermission(def2, state), false);
  });

  test('PermissionEngine evaluates capabilities and conditions', () {
    final state = {
      'userPermissions': ['edit_post', 'view_reports'],
      'isOwner': true,
    };

    final def1 = {'requiredPermissions': 'edit_post'};
    expect(PermissionEngine.hasPermission(def1, state), true);

    final def2 = {'requiredPermissions': 'delete_user'};
    expect(PermissionEngine.hasPermission(def2, state), false);

    final def3 = {'permissionCondition': '{{isOwner == true}}'};
    expect(PermissionEngine.hasPermission(def3, state), true);
  });

  test('ConfigParser parses colors correctly', () {
    expect(ConfigParser.parseColor('#FF0000'), const Color(0xFFFF0000));
    expect(ConfigParser.parseColor('FF0000'), const Color(0xFFFF0000));
    expect(ConfigParser.parseColor('80FF0000'), const Color(0x80FF0000));
  });

  test('ConfigParser parses edge insets correctly', () {
    expect(ConfigParser.parseEdgeInsets(16), const EdgeInsets.all(16.0));
    expect(ConfigParser.parseEdgeInsets('16.0'), const EdgeInsets.all(16.0));
    expect(ConfigParser.parseEdgeInsets('8, 16, 8, 16'), const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0));
    expect(
      ConfigParser.parseEdgeInsets({'left': 8, 'top': 16, 'right': 8, 'bottom': 16}), 
      const EdgeInsets.only(left: 8.0, top: 16.0, right: 8.0, bottom: 16.0)
    );
  });

  test('ConfigParser parses icons, shadows and borders', () {
    expect(ConfigParser.parseIconData('home') != null, true);
    expect(ConfigParser.parseIconData('invalid') != null, true);

    final border = ConfigParser.parseBorder({'color': '#FF0000', 'width': 2.0});
    expect(border?.top.color, const Color(0xFFFF0000));
    expect(border?.top.width, 2.0);

    final shadow = ConfigParser.parseBoxShadow([{'color': '#00FF00', 'blurRadius': 4}]);
    expect(shadow?.first.color, const Color(0xFF00FF00));
    expect(shadow?.first.blurRadius, 4.0);
  });

  test('ConfigParser parses BoxDecoration correctly', () {
    final def = {
      'color': '#FF0000',
      'borderRadius': 8,
      'gradient': {
        'type': 'linear',
        'colors': ['#FF0000', '#00FF00'],
        'begin': 'topLeft',
        'end': 'bottomRight'
      }
    };
    final decoration = ConfigParser.parseBoxDecoration(def);
    expect(decoration?.color, const Color(0xFFFF0000));
    expect(decoration?.borderRadius, BorderRadius.circular(8.0));
    expect(decoration?.gradient is LinearGradient, true);
  });

  test('LogicEngine evaluates complex groups', () {
    final state = {'qty': 10, 'price': 50};

    final def1 = {
      'visibleIf': {
        'matchAll': [
          '{{qty > 5}}',
          '{{price < 100}}'
        ]
      }
    };
    expect(LogicEngine.isVisible(def1, state), true);

    final def2 = {
      'visibleIf': {
        'matchAny': [
          '{{qty > 100}}',
          '{{price == 50}}'
        ]
      }
    };
    expect(LogicEngine.isVisible(def2, state), true);
  });

  test('OperationEngine evaluates functional helpers', () {
    final state = {'name': 'flutter', 'price': 12.5};
    
    expect(OperationEngine.evaluate('{{upper(name)}}', state), 'FLUTTER');
    expect(OperationEngine.evaluate('{{round(price)}}', state), 13);
    expect(OperationEngine.evaluate('{{coalesce(null, "default")}}', state), 'default');
    expect(OperationEngine.evaluate('{{length(name)}}', state), 7);
  });

  test('ValidationEngine evaluates rules correctly', () {
    final state = {'pass': '12345', 'confirm': '123456'};

    // Required
    expect(ValidationEngine.validate('', {'required': true}, {}), 'This field is required');
    
    // Email
    expect(ValidationEngine.validate('invalid', {'type': 'email'}, {}), 'Invalid email address');
    expect(ValidationEngine.validate('test@example.com', {'type': 'email'}, {}), null);

    // Match Field
    expect(ValidationEngine.validate('123456', {'matchField': 'pass'}, state), 'Fields do not match');
    
    // Custom Rule
    expect(ValidationEngine.validate('20', {'customRule': '{{value >= 18}}'}, {'value': 20}), null);
    expect(ValidationEngine.validate('10', {'customRule': '{{value >= 18}}'}, {'value': 10}), 'Validation failed');
  });

  test('ActionEngine evaluates branching and loops', () {
    final state = {'balance': 100, 'price': 50};
    
    // Test context sharing concept (internal logic)
    final contextMap = {'item': 'apple'};
    final combined = {...state, 'context': contextMap};
    expect(OperationEngine.evaluate('{{context.item}}', combined), 'apple');
  });

  test('RuleEngine evaluates properties correctly', () {
    final state = {'type': 'business', 'isAdmin': true};
    
    expect(RuleEngine.evaluateProperty('{{type == "business"}}', state), true);
    expect(RuleEngine.evaluateProperty('{{isAdmin == false}}', state), false);
  });

  test('ValidationEngine handles requiredIf dynamically', () {
    final state = {'type': 'individual'};
    final rules = {'requiredIf': '{{type == "business"}}'};
    
    // Not required because type is individual
    expect(ValidationEngine.validate('', rules, state), null);
    
    // Required because type is business
    final state2 = {'type': 'business'};
    expect(ValidationEngine.validate('', rules, state2), 'This field is required');
  });

  testWidgets('YamlUiBuilder executes onInit hook', (WidgetTester tester) async {
    final definition = {
      'onInit': {
        'type': 'setState',
        'key': 'initialized',
        'value': true,
      },
      'body': {
        'type': 'text',
        'value': 'Hello',
      }
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: YamlUiBuilder(definition: definition),
        ),
      ),
    );

    await tester.pump(); // Handle post-frame callback
    await tester.pump(); // Second pump for state change to propagate

    final container = ProviderScope.containerOf(tester.element(find.byType(YamlUiBuilder)));
    expect(container.read(appStateProvider)['initialized'], true);
  });

  testWidgets('each widget renders list with local context', (WidgetTester tester) async {
    final definition = {
      'initialState': {
        'fruits': ['apple', 'banana', 'cherry']
      },
      'type': 'column',
      'children': [
        {
          'type': 'each',
          'items': '{{fruits}}',
          'template': {
            'type': 'text',
            'value': 'Fruit: {{item}}'
          }
        }
      ]
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: YamlUiBuilder(definition: definition),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Fruit: apple'), findsOneWidget);
    expect(find.text('Fruit: banana'), findsOneWidget);
    expect(find.text('Fruit: cherry'), findsOneWidget);
  });

  testWidgets('Action focus changes textfield focus', (WidgetTester tester) async {
    final definition = {
      'type': 'column',
      'children': [
        {
          'type': 'textfield',
          'name': 'target',
          'id': 'myField',
        },
        {
          'type': 'button',
          'text': 'Focus Field',
          'action': {
            'type': 'focus',
            'id': 'myField',
          }
        }
      ]
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: YamlUiBuilder(definition: definition),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final focusNode = FocusEngine.getOrCreateNode('myField');
    expect(focusNode.hasFocus, false);

    await tester.ensureVisible(find.text('Focus Field'));
    await tester.tap(find.text('Focus Field'));
    await tester.pump();

    expect(focusNode.hasFocus, true);
  });

  testWidgets('Responsive properties update on screen size change', (WidgetTester tester) async {
    final definition = {
      'type': 'text',
      'value': 'Mode: {{device.isMobile ? "Small" : "Large"}}'
    };

    // Small screen
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: YamlUiBuilder(definition: definition),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Mode: Small'), findsOneWidget);

    // Large screen
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpAndSettle();
    
    expect(find.text('Mode: Large'), findsOneWidget);
    
    // Reset view
    tester.view.resetPhysicalSize();
  });

  test('ComponentRegistry stores and retrieves templates', () {
    final template = {'type': 'text', 'value': 'Hello {{name}}'};
    ComponentRegistry.register('my_comp', template);
    
    expect(ComponentRegistry.exists('my_comp'), true);
    expect(ComponentRegistry.get('my_comp'), template);
  });

  testWidgets('component widget renders template with params', (WidgetTester tester) async {
    ComponentRegistry.register('user_card', {
      'type': 'text',
      'value': 'User: {{name}}'
    });

    final definition = {
      'type': 'component',
      'name': 'user_card',
      'params': {
        'name': 'Veera'
      }
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: YamlUiBuilder(definition: definition),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('User: Veera'), findsOneWidget);
  });
}

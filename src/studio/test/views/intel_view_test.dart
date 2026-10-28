import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:studio/views/intel_view.dart';

Widget _buildApp(Set<String> adopted, ValueChanged<String> onToggle) {
  return MaterialApp(
    home: Scaffold(
      body: IntelView(adoptedIntel: adopted, onToggleIntel: onToggle),
    ),
  );
}

void main() {
  group('IntelView', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(_buildApp({'intel1', 'intel2'}, (_) {}));
      expect(find.text('情 报 看 板'), findsOneWidget);
    });

    testWidgets('renders all five intel cards with badges', (tester) async {
      await tester.pumpWidget(_buildApp({'intel1', 'intel2'}, (_) {}));

      expect(find.text('确凿'), findsNWidgets(2));
      expect(find.text('推测'), findsNWidgets(2));
      expect(find.text('存疑'), findsOneWidget);
    });

    testWidgets('shows adopted items in panel', (tester) async {
      await tester.pumpWidget(_buildApp({'intel1', 'intel2'}, (_) {}));

      expect(find.text('- 区兵团沿睢杞大道西进'), findsOneWidget);
      expect(find.text('- 蒋令邱区东西对进'), findsOneWidget);
    });

    testWidgets('shows empty state when nothing adopted', (tester) async {
      await tester.pumpWidget(_buildApp({}, (_) {}));

      expect(find.text('尚未采信'), findsOneWidget);
    });

    testWidgets('tapping card toggles adoption', (tester) async {
      final toggled = <String>[];
      await tester.pumpWidget(_buildApp({'intel1', 'intel2'}, (id) => toggled.add(id)));

      await tester.tap(find.textContaining('区兵团电'));
      expect(toggled, ['intel1']);
    });

    testWidgets('renders adopted panel when all intel toggled off', (tester) async {
      await tester.pumpWidget(_buildApp({}, (_) {}));
      expect(find.text('尚未采信'), findsOneWidget);
    });
  });
}

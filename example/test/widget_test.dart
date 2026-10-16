import 'package:animated_box_decoration/animated_box_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('animates the decorations when tapping the button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(SmoothAnimatedContainer), findsWidgets);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

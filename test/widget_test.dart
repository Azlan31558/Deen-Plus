import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:islamicapp/main.dart';

void main() {
  testWidgets('app loads the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

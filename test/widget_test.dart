import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:condos/app.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: CondosApp()));

    // Verify that splash screen shows
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coffee_finder_app/main.dart';

void main() {
  testWidgets('Coffee Finder App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CoffeeFinderApp());

    // Allow the app to load
    await tester.pumpAndSettle();

    // Check if the bottom navigation is visible
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.list_outlined), findsOneWidget);
    expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });
}
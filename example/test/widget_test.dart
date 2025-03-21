// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_voip_push_notification_example/main.dart';

void main() {
  testWidgets('Verify Token Received', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that voip push token is received
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Text &&
            (widget.data?.startsWith('Received Voip Push token received:') ??
                false),
      ),
      findsOneWidget,
    );
  });
}

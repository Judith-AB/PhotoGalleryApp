import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_gallery_app/main.dart';

void main() {
  testWidgets('Add photo button test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(PhotoGalleryApp());

    // Check that the initial message is shown
    expect(find.text("No photos added yet"), findsOneWidget);

    // Tap the "Add Photo" button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle(); // Wait for UI to update

    // Check that a photo has been added
    expect(find.textContaining("Photo"), findsWidgets);
  });
}

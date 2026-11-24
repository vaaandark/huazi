import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:huazi/ui/widgets/practice_grid.dart';

void main() {
  testWidgets('田字格能渲染子元素', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: PracticeGrid(child: Center(child: Text('永'))),
          ),
        ),
      ),
    );
    expect(find.text('永'), findsOneWidget);
  });
}

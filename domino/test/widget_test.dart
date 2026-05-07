import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:domino/main.dart';
import 'package:domino/telaLogin.dart';

void main() {
  testWidgets('renderiza a tela de login', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DominoQuimicaApp());

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
